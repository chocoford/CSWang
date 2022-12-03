//
//  ChannelView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/2.
//

import SwiftUI

struct ChannelView: View {
    @EnvironmentObject var store: AppStore

    @State private var workspace: WorkspaceData? = nil
//    var workspace: WorkspaceData? {
//        store.state.workspace.currentWorkspace
//    }
    
    var channel: GroupData? {
        store.state.workspace.channel.channelInfo
    }
    
    var memberInfo: MemberData? {
        workspace?.userMemberInfo
    }
    
    var body: some View {
        if let workspace = workspace,
           let channel = channel {
            VStack {
                AvatarView(url: URL(string: memberInfo?.avatarURL ?? ""),
                           fallbackText: String(memberInfo?.name.prefix(2) ?? ""),
                           size: 80)
                
                Text(memberInfo?.name ?? "Unknown")
                    .font(.title)
                    .fontWeight(.bold)
                Text(workspace.name)
                Spacer()
                
                ShitInfoView()
            }
        } else {
            CreateChannelView()
        }

    }
}

struct ChannelView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelView()
            .environmentObject(AppStore.preview)
    }
}
