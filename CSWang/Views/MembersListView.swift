//
//  MembersListView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/2.
//

import SwiftUI

struct MembersListView: View {
    var members: [MemberData]?
    
    @Binding var selectedMemberIDs: Set<String>
//    @State var selectedMemberIDs = Set<String>()
    
    var body: some View {
        if let members = members {
            List {
                ForEach(members, id: \.memberID) { member in
                    Button {
                        if selectedMemberIDs.contains(member.memberID) {
                            selectedMemberIDs.remove(member.memberID)
                        } else {
                            selectedMemberIDs.insert(member.memberID)
                        }
                    } label: {
                        HStack {
                            AvatarView(url: URL(string: member.avatarURL),
                                       fallbackText: String(member.name.prefix(2)))
                            Text(member.name)
                            Spacer()
                            
                            Toggle(isOn: .constant(selectedMemberIDs.contains(member.memberID))) {}
                        }
                    }
                    .buttonStyle(ListButtonStyle())
                }
            }
            
        } else {
            LoadingView()
        }
        
    }
}

struct MembersListView_Previews: PreviewProvider {
    static let store = AppStore.preview
    static var previews: some View {
        MembersListView(members: store.state.workspace.allMembers, selectedMemberIDs: .constant([]))
//            .environmentObject()
    }
}
