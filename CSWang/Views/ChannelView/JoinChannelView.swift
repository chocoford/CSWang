//
//  JoinChannelView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/13.
//

import SwiftUI

struct JoinChannelView: View {
    @EnvironmentObject var store: AppStore
    
    var workspace: WorkspaceData? {
        store.state.workspace.currentWorkspace
    }
    
    var channel: Loadable<GroupData> {
        store.state.workspace.channel.currentChannel
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
        guard let workspace = workspace,
              let channel = channel.value,
              let member = memberInfo else { return }
        joining = true
        await store.send(.chanshi(action: .joinCSChannel(workspaceID: workspace.workspaceID,
                                                         channelID: channel.groupID,
                                                         memberID: member.memberID)))
        joining = true
    }
}

struct JoinChannelView_Previews: PreviewProvider {
    static var previews: some View {
        JoinChannelView()
    }
}
