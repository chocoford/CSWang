//
//  WorkspaceDetailView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/1.
//

import SwiftUI
import Combine

struct WorkspaceDetailView: View {
    @EnvironmentObject var store: AppStore
//    @State private var workspace: WorkspaceData? = nil
    var workspace: WorkspaceData? {
        store.state.workspace.currentWorkspace
    }
    var memberInfo: MemberData? {
        workspace?.userMemberInfo
    }
    
//    init(workspace: WorkspaceData?) {
//        self.workspace = workspace
//    }
    
    var body: some View {
        content
        .onChange(of: store.state.workspace.currentWorkspace, perform: { workspace in
            guard let workspace = workspace else {
                return
            }
            Task {
                await store.send(.channel(action: .listPrivateChannels(workspaceID: workspace.workspaceID, memberID: workspace.userMemberInfo.memberID)))
                await store.send(.workspace(action: .listWorkspaceMembers(workspaceID: workspace.workspaceID)))
            }
        })
//        .onReceive(store.state.workspace.currentWorkspace, perform: {workspace in
//            self.workspace = workspace
//            guard let workspace = workspace else {
//                return
//            }
//            Task {
//                await store.send(.workspace(action: .listWorkspaceMembers(workspaceID: workspace.workspaceID)))
//            }
//        })
    }
    
    @ViewBuilder private var content: some View {
        if let _ = workspace {
            ChannelView()
        } else {
            Text("Choose a workspace")
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
