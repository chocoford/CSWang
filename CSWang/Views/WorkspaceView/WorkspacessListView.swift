//
//  WorkspacessListView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/1.
//

import SwiftUI
import Combine
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif


struct WorkspacesListView: View {
    @EnvironmentObject var store: AppStore
    var workspaces: Loadable<[WorkspaceData]> {
        store.state.workspace.allWorkspaces
    }
    
    var workspace: WorkspaceData? {
        store.state.workspace.currentWorkspace
    }
    
    var body: some View {
        compatibleNavigationView
    }
    
    @ViewBuilder private var compatibleNavigationView: some View {
        if #available(iOS 16.0, *), #available(macOS 13.0, *) {
            NavigationSplitView {
                content
                    .navigationTitle("Workspaces")
            } detail: {
                WorkspaceDetailView()
            }
        } else {
            NavigationView {
                content
                    .navigationTitle("Workspaces")
            }
        }
    }
    
    @ViewBuilder private var content: some View {
        switch workspaces {
            case .notRequested:
                notRequestedView
            case .isLoading(let last):
                loadingView(last)
            case .loaded(let workspaces):
                loadedView(workspaces: workspaces)
            case .failed(let error):
                failedView(error)
        }
    }
}

// MARK: - Side effects
extension WorkspacesListView {
    private func reloadWorkspaces() async {
        
        guard let userID = store.state.user.userInfo.value?.user.id else {
            return
        }
        
        
        
        await store.send(.workspace(action: .listWorkspaces(userID: userID)))
    }
    
    private func setCurrentWorkspace(workspaceID: String?) {
        Task {
            await store.send(.workspace(action: .setCurrentWorkspace(workspaceID: workspaceID)))
        }
    }
}

// MARK: - Loading Content
private extension WorkspacesListView {
    var notRequestedView: some View {
        Text("No data").task {
            await reloadWorkspaces()
        }
    }
    
    func loadingView(_ previouslyLoaded: [WorkspaceData]?) -> some View {
        LoadingView { _ in
            Text("Loading...")
        }
    }
    
    func failedView(_ error: Error) -> some View {
        ErrorView(error: error, retryAction: {
            Task {
                await self.reloadWorkspaces()
            }
        })
    }
}

// MARK: - Displaying Content
extension WorkspacesListView {
    private var selectedWorkspaceID: Binding<String?> {
        store.binding(for: \.workspace.currentWorkspaceID) {
            .workspace(action: .setCurrentWorkspace(workspaceID: $0))
        }
    }
    
    func loadedView(workspaces: [WorkspaceData]) -> some View {
        VStack {
            CellList(workspaces, selection: selectedWorkspaceID) { workspace in
                NavigationCellView(value: workspace, selection: selectedWorkspaceID) {
                    WorkspaceCellView(workspace: workspace,
                                      selected: selectedWorkspaceID.wrappedValue == workspace.workspaceID)
                } destination: {
                    WorkspaceDetailView()
                }
            }
            Divider()
            toolbarContent
                .padding(.horizontal)
        }
    }
}

// MARK: - Toolbar Content
extension WorkspacesListView {
    @ViewBuilder
    private var toolbarContent: some View {
        switch store.state.user.userInfo {
            case .notRequested:
                EmptyView()
            case .loaded(let data):
                userInfoToolbar(userInfo: data)
            case .isLoading(let last):
                userInfoToolbar(userInfo: last)
            case .failed(_):
                userInfoToolbar(userInfo: nil)
        }
    }
    
        @ViewBuilder
    private func userInfoToolbar(userInfo: UserInfo?) -> some View {
#if os(iOS)
        toolbarContent_iOS(userInfo)
#else
        toolbarContent_macOS(userInfo)
#endif
    }

    func toolbarContent_iOS(_ userInfo: UserInfo?) -> some View {
        HStack {
            if let userInfo = userInfo {
                AvatarView(url: userInfo.user.avatarURL,
                           fallbackText: String((userInfo.user.name ?? "?").prefix(2)))
                Text(userInfo.user.name ?? "Unknown")
                    .lineLimit(1)
                Spacer()
                LogoutButton()
            } else {
                Image(systemName: "person.circle")
                    .resizable()
                    .scaledToFit()
                Text("Log in")
            }
        }
    }
    
    func toolbarContent_macOS(_ userInfo: UserInfo?) -> some View {
        HStack {
            if let userInfo = userInfo {
                AvatarView(url: userInfo.user.avatarURL,
                           fallbackText: String((userInfo.user.name ?? "?").prefix(2)))
                Text(userInfo.user.name ?? "Unknown")
                    .lineLimit(1)
                Spacer()
                LogoutButton()
            } else {
                Image(systemName: "person.circle")
                    .resizable()
                    .scaledToFit()
                Text("Log in")
            }
        }
    }
}


#if DEBUG
struct WorkspacesListView_Previews: PreviewProvider {
    static var previews: some View {
        WorkspacesListView()
            .environmentObject(AppStore.preview)
    }
}
#endif
