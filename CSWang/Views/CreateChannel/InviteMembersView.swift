//
//  InviteMembersView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/3.
//

import SwiftUI

struct InviteMembersView: View {
    @EnvironmentObject var store: AppStore
    
    var workspace: WorkspaceData? {
        store.state.workspace.currentWorkspace
    }
//    @State private var workspace: WorkspaceData?
    @State private var searchText: String = ""
    @State private var invitedMemberIDs = Set<String>()
    @State private var preInvitedMemberIDs = Set<String>()
    @State private var showAddMembersSheet: Bool = false
    
    var invitedMembers: [MemberData] {
        invitedMemberIDs.compactMap {
            store.state.workspace.members?[$0]
        }
    }
    
//    init(worksapce: WorkspaceData? = nil) {
//        self.workspace = worksapce
//    }

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
        .toolbar(content: {
            Button {
                Task {
                    await createChannel()
                }
            } label: {
                Text("Create")
            }
        })
        .sheet(isPresented: $showAddMembersSheet) {
            VStack {
                MembersListView(members: store.state.workspace.allMembers?.filter {
                    $0.memberID != workspace?.userMemberInfo.memberID
                },
                                selectedMemberIDs: $preInvitedMemberIDs)
                .frame(minWidth: 400, minHeight: 300)
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
//        .onReceive(store.state.workspace.currentWorkspace) {
//            workspace = $0
//        }
        .onChange(of: invitedMemberIDs) { newValue in
                   preInvitedMemberIDs = newValue
        }
    }
    
    func createChannel() async {
        guard let workspace = workspace else {
            return
        }
        await store.send(.channel(action: .createChannel(workspaceID: workspace.workspaceID,
                                                         memberID: workspace.userMemberInfo.memberID,
                                                         invitedMemberIDs: Array(invitedMemberIDs) + [workspace.userMemberInfo.memberID])))
    }
}

struct InviteMembersView_Previews: PreviewProvider {
    static var previews: some View {
        InviteMembersView()
            .environmentObject(AppStore.preview)
    }
}
