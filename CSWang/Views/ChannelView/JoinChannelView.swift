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
    
    var memberInfo: MemberData? {
        workspace?.userMemberInfo
    }
    
    @State private var joining: Bool = false {
        didSet {
            if joining {
                Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { _ in
                    joining  = false
                }
            }
        }
    }
    
    
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
            .disabled(joining)
        }
    }
}

//MARK: - Side Effects
private extension JoinChannelView {
    private func joinChannel() async {
        joining = true
        await store.send(.workspace(action: .joinCSChannel))
        joining = false
    }
}

struct JoinChannelView_Previews: PreviewProvider {
    static var previews: some View {
        JoinChannelView()
    }
}
