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


struct WorkspacessListView: View {
    @EnvironmentObject var store: AppStore
    var workspaces: Loadable<[WorkspaceData]> {
        store.state.workspace.workspaces.map {
            $0.values.sorted {
                $0.createAt < $1.createAt
            }
        }
    }
    @State private var selectedWorkspace: WorkspaceData?
    
    var body: some View {
        NavigationSplitView {
            content
            .navigationTitle("Workspaces")
            .toolbar {
                LogoutButton()
            }
            .onReceive(store.state.user.hasLogin) { hasLogin in
                if hasLogin {
                    Task {
                        await reloadWorkspaces()
                    }
                }
            }
        } detail: {
            WorkspaceDetailView()
        }
//        .onReceive(store.state.workspace.workspaces) { workspaces in
//            self.workspaces = workspaces.map({ workspaces in
//                workspaces.values.sorted {
//                    $0.createAt < $1.createAt
//                }
//            })
//        }
        
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
extension WorkspacessListView {
    private func reloadWorkspaces() async {
        guard let userID = store.state.user.userInfo?.user.id else {
            print("no userID")
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
private extension WorkspacessListView {
    var notRequestedView: some View {
        Text("No data").task {
            await reloadWorkspaces()
        }
    }
    
    func loadingView(_ previouslyLoaded: [WorkspaceData]?) -> some View {
        Text("loading")
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
extension WorkspacessListView {
    func loadedView(workspaces: [WorkspaceData]) -> some View {
        VStack {
            List(workspaces, selection: $selectedWorkspace) { workspace in
                NavigationCellView(value: workspace) {
                    WorkspaceCellView(workspace: workspace,
                                      selected: selectedWorkspace?.workspaceID == workspace.workspaceID)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
#if os(iOS)
                .listRowBackground(Color.init(uiColor: .systemBackground))
#elseif os(macOS)
                .listRowBackground(Color.init(nsColor: .textBackgroundColor))
#endif
            }
            .listStyle(.plain)
            .onChange(of: selectedWorkspace, perform: { newValue in
                setCurrentWorkspace(workspaceID: newValue?.workspaceID)
            })
            Divider()
            HStack {
                AvatarView(url: store.state.user.userInfo?.user.avatarUrl,
                           fallbackText: String((store.state.user.userInfo?.user.name ?? "?").prefix(2)))
                Text(store.state.user.userInfo?.user.name ?? "Unknown")
                Spacer()
                Button {
                     
                } label: {
                    Image(systemName: "gear")
                }
            }
            .padding(.horizontal)
        }
       
    }
}



struct WorkspacessListView_Previews: PreviewProvider {
    static var previews: some View {
        WorkspacessListView()
            .environmentObject(AppStore.preview)
    }
}
