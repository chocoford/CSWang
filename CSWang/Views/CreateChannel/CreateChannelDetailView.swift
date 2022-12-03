//
//  CreateChannelDetailView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/3.
//

import SwiftUI

struct CreateChannelDetailView: View {
    @EnvironmentObject var store: AppStore
    @State private var invitedMemberIDs = Set<String>()

    var body: some View {
        Form {
           Section {
               VStack {
                   MembersListView(members: store.state.workspace.allMembers,
                                   selectedMemberIDs: $invitedMemberIDs)

               }
                
           } header: {
               HStack {
                   Text("Invite members")
                   Spacer()
                   Button {
                       
                   } label: {
                       Text("Add members")
                   }
               }
           }
            Button {
                
            } label: {
                Text("Done")
            }
            .buttonStyle(PrimaryButtonStyle(block: true))
        }
        .navigationTitle("Create a channel")

    }
}

struct CreateChannelDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CreateChannelDetailView()
            .environmentObject(AppStore.preview)

    }
}
