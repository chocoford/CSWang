//
//  InviteMembersView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/3.
//

import SwiftUI

struct InviteMembersView: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText: String = ""
    @State private var invitedMemberIDs = Set<String>() {
        willSet(val) {
            preInvitedMemberIDs = val
        }
    }
    @State private var preInvitedMemberIDs = Set<String>()
    @State private var showAddMembersSheet: Bool = false
    
    var invitedMembers: [MemberData] {
        invitedMemberIDs.compactMap {
            store.state.workspace.members?[$0]
        }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    TextField(text: $searchText, label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .resizable()
                                .scaledToFit()
                            Text("Search")
                        }
                    })
                    .textFieldStyle(.roundedBorder)
                    
                    Button {
                        showAddMembersSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                /// Selected members View
                ForEach(invitedMembers, id: \.memberID) { member in
                    HStack {
                        AvatarView(url: URL(string: member.avatarURL), fallbackText: String(member.name.prefix(2)))
                        Text(member.name)
                        Spacer()
                        
                        Button {
                            invitedMemberIDs.remove(member.memberID)
                        } label: {
                            Text("Remove")
                        }
                        
                    }
                }
            }
        }
        .navigationTitle("Invite members")
        .sheet(isPresented: $showAddMembersSheet) {
            VStack {
                MembersListView(members: store.state.workspace.allMembers,
                                selectedMemberIDs: $preInvitedMemberIDs)
                .frame(width: 400, height: 300)
                HStack {
                    Button {
                        showAddMembersSheet = false
                    } label: {
                        Text("Cancel")
                    }
                    Button {
                        invitedMemberIDs = preInvitedMemberIDs
                        showAddMembersSheet = false
                    } label: {
                        Text("Confirm")
                    }
                }
            }
        }
    }
}

struct InviteMembersView_Previews: PreviewProvider {
    static var previews: some View {
        InviteMembersView()
            .environmentObject(AppStore.preview)
    }
}
