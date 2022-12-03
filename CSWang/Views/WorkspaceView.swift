//
//  WorkspaceView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/1.
//

import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif


struct WorkspaceView: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        NavigationSplitView {
            List(selection: $store.state.workspace.currentWorkspaceID, content: {
                ForEach(store.state.workspace.allWorkspaces) { workspace in
                    NavigationCellView(value: workspace.workspaceID) {
                        WorkspaceCellView(workspace: workspace,
                                          selected: store.state.workspace.currentWorkspaceID == workspace.workspaceID)
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    #if os(iOS)
                    .listRowBackground(Color.init(uiColor: .systemBackground))
                    #elseif os(macOS)
                    .listRowBackground(Color.init(nsColor: .textBackgroundColor))
                    #endif
                }
            })
            .listStyle(.plain)
            .navigationTitle("Workspaces")
            .toolbar {
                Button {
                    AuthMiddleware.shared.removeToken()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                }
            }
            .onReceive(store.state.user.hasLogin) { hasLogin in
                if hasLogin {
                    Task {
                        await loadWorkspaces()
                    }
                }
            }
        } detail: {
            WorkspaceDetailView()
        }
    }
    
    private func loadWorkspaces() async {
        guard let userID = store.state.user.userInfo?.user.id else {
            print("no userID")
            return
        }
        await store.send(.workspace(action: .listWorkspaces(userID: userID)))
    }
}

struct WorkspaceView_Previews: PreviewProvider {
    static var previews: some View {
        WorkspaceView()
            .environmentObject(AppStore.preview)
    }
}
