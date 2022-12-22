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

    var workspace: WorkspaceData? {
        store.state.workspace.currentWorkspace
    }
    var memberInfo: MemberData? {
        workspace?.userMemberInfo
    }
    
    var body: some View {
        content
        .onChange(of: workspace, perform: { _ in
           loadWorkspaceDetails()
        })
    }
    
    @ViewBuilder private var content: some View {
        if let _ = workspace {
            ChannelView()
        } else {
            Text("Choose a workspace")
        }
    }
}

private extension WorkspaceDetailView {
    func loadWorkspaceDetails() {
        Task {
            await store.send(.workspace(action: .listWorkspaceChannels))
            await store.send(.workspace(action: .listWorkspaceMembers))
        }
    }
}



#if DEBUG
struct WorkspaceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        WorkspaceDetailView()
            .environmentObject(AppStore.preview)
    }
}
#endif
