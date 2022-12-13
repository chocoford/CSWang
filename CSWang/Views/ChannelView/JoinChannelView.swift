//
//  JoinChannelView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/13.
//

import SwiftUI

struct JoinChannelView: View {
    @EnvironmentObject var store: AppStore
    
    var workspaceState: WorkspaceState {
        store.state.workspace
    }
    
    var workspace: WorkspaceData? {
        workspaceState.currentWorkspace
    }
    
    var channel: Loadable<GroupData> {
        workspaceState.currentChannel
    }
    
    var memberInfo: MemberData? {
        workspace?.userMemberInfo
    }
    
    @State private var joining: Bool = false
    
    
    var body: some View {
        VStack {
            Text("It seems that there is already a channel.")
            Button {
                Task {
                    await joinChannel()
                }
            } label: {
                Text("Join")
            }
            .buttonStyle(PrimaryButtonStyle(loading: joining))
        }
    }
}

//MARK: - Side Effects
private extension JoinChannelView {
    private func joinChannel() async {
        joining = true
        await store.send(.workspace(action: .joinCSChannel))
        joining = true
    }
}

struct JoinChannelView_Previews: PreviewProvider {
    static var previews: some View {
        JoinChannelView()
    }
}
