//
//  CreateChannelView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/2.
//

import SwiftUI

struct CreateChannelView: View {
    @EnvironmentObject var store: AppStore
    
    var workspace: WorkspaceData? {
        store.state.workspace.currentWorkspace
    }
    
    
    var body: some View {
        VStack {
            VStack{
                Text("Initialize")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Create a channel to start")
            }
            .padding()
            
            Button {
                Task {
                    await createChannel()
                }
            } label: {
                Text("Create the channel")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
    
    func createChannel() async {
        guard let workspace = workspace else {
            return
        }
        await store.send(.channel(action: .createChannel(workspaceID: workspace.workspaceID,
                                                         memberID: workspace.userMemberInfo.memberID,
                                                         invitedMemberIDs: [])))
        if let channelID = store.state.workspace.channel.currentChannel.value?.groupID {
            await store.send(.chanshi(action: .joinCSChannel(workspaceID: workspace.workspaceID,
                                                             channelID: channelID,
                                                             memberID: workspace.userMemberInfo.memberID)))
        }
    }
}

struct CreateChannelView_Previews: PreviewProvider {
    static var previews: some View {
        CreateChannelView()
    }
}
