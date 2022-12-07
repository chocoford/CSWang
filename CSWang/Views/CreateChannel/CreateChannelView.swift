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
//        NavigationStack {
            VStack {
                VStack{
                    Text("Initialize")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Create a channel to start")
                }
                .padding()

//                NavigationLink("Create the channel") {
//                   InviteMembersView()
//                }
                Button {
                    Task {
                        await createChannel()
                    }
                } label: {
                    Text("Create the channel")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            
//        }
    }
    
    func createChannel() async {
        guard let workspace = workspace else {
            return
        }
        await store.send(.channel(action: .createChannel(workspaceID: workspace.workspaceID,
                                                         memberID: workspace.userMemberInfo.memberID,
                                                         invitedMemberIDs: [])))
        if let channelID = store.state.workspace.channel.currentChannel.value?.groupID {
            await store.send(.channel(action: .createTrickle(workspaceID: workspace.workspaceID,
                                                             channelID: channelID,
                                                             payload: .init(authorMemberID: workspace.userMemberInfo.memberID,
                                                                            blocks: TrickleIntergratable.createPost(type: .helloWorld),
                                                                            mentionedMemberIDs: []))))
        }
    }
}

struct CreateChannelView_Previews: PreviewProvider {
    static var previews: some View {
        CreateChannelView()
    }
}
