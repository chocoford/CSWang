//
//  WorkspaceDetailView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/1.
//

import SwiftUI

struct WorkspaceDetailView: View {
    @EnvironmentObject var store: AppStore

//    @State private var loading: Bool = false
    @State private var workspace: WorkspaceData? = nil
//    var workspace: WorkspaceData? {
//        store.state.workspace.currentWorkspace
//    }
    var memberInfo: MemberData? {
        workspace?.userMemberInfo
    }
    
    var body: some View {
        ZStack {
            if let workspace = workspace {
                ChannelView()
            } else {
                Text("Choose a workspace")
            }
        }
        .onReceive(store.state.workspace.currentWorkspace) { workspace in
            guard let workspace = workspace else {
                return
            }
            self.workspace = workspace
            Task {
                await store.send(.workspace(action: .listWorkspaceMembers(workspaceID: workspace.workspaceID)))
            }
        }
    }
    
    private func findShitChannel() async {
        guard let workspace = workspace,
              let memberInfo = memberInfo else {
            return
        }
        await store.send(.channel(action: .listPrivateChannels(workspaceID: workspace.workspaceID,
                                                                 memberID: memberInfo.memberID)))
    }
}

struct WorkspaceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        WorkspaceDetailView()
            .environmentObject(AppStore.preview)
    }
}
