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
    
    @State private var creating = false
    
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
            .buttonStyle(PrimaryButtonStyle(loading: creating))
        }
    }
    
    func createChannel() async {
        creating = true
        await store.send(.workspace(action: .createTeamChannel(invitedMemberIDs: [])))
//        await store.send(.workspace(action: .joinCSChannel))
        creating = false
    }
}

struct CreateChannelView_Previews: PreviewProvider {
    static var previews: some View {
        CreateChannelView()
    }
}
