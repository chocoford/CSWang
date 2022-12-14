//
//  ParticipantsView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/6.
//

import SwiftUI

struct ParticipantsView: View {
    @EnvironmentObject var store: AppStore
    
    
    var worksapceState: WorkspaceState {
        store.state.workspace
    }
    
    var workspace: WorkspaceData? {
        worksapceState.currentWorkspace
    }
    
    
    var members: [MemberData] {
        store.state.workspace.allMembers ?? []
    }
    
    var body: some View {
        content
    }
    
    @ViewBuilder private var content: some View {
        switch worksapceState.allParticipants {
            case .notRequested:
                notRequestedView
            case .isLoading(let last):
                loadingView(last)
            case .loaded(let data):
                loadedView(data)
            case .failed(let error):
                failedView(error)
        }
    }
}


//MARK: - Side Effects
extension ParticipantsView {

}

// MARK: - Loading Content
private extension ParticipantsView {
    var notRequestedView: some View {
        Text("No data")
    }
    
    func loadingView(_ previouslyLoaded: [MemberData]?) -> some View {
        VStack {
            LoadingView { progress in
                Text("Loading...")
            }
        }
    }
    
    func failedView(_ error: Error) -> some View {
        ErrorView(error: error, retryAction: {
        })
    }
}

extension ParticipantsView {
    func loadedView(_ data: [MemberData]) -> some View {
        ScrollView {
            ForEach(data, id: \.memberID) { participant in
                HStack {
                    AvatarView(url: URL(string: participant.avatarURL), fallbackText: participant.name.prefix(2))
                    Text(participant.name)
                    Spacer()
                }
                .padding()
                .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal)
    }
}
#if DEBUG
struct ParticipantsView_Previews: PreviewProvider {
    static var previews: some View {
        ParticipantsView()
            .environmentObject(AppStore.preview)
    }
}
#endif
