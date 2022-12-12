//
//  ParticipantsView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/6.
//

import SwiftUI

struct ParticipantsView: View {
    @EnvironmentObject var store: AppStore
    
    var csState: CSState {
        store.state.workspace.channel.chanshi
    }
    
    var workspace: WorkspaceData? {
        store.state.workspace.currentWorkspace
    }
    
    var channel: Loadable<GroupData> {
        store.state.workspace.channel.currentChannel
    }
    
    var members: [MemberData] {
        store.state.workspace.allMembers ?? []
    }
    
    var body: some View {
        content
    }
    
    @ViewBuilder private var content: some View {
        switch csState.allParticipants {
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
    private func loadParticipants() async {
        await store.send(.chanshi(action: .loadParticipants(channelMembers: members)))
    }
}

// MARK: - Loading Content
private extension ParticipantsView {
    var notRequestedView: some View {
        Text("No data")
//            .onAppear {
//                Task {
//                    await loadParticipants()
//                }
//            }
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

struct ParticipantsView_Previews: PreviewProvider {
    static var previews: some View {
        ParticipantsView()
            .environmentObject(AppStore.preview)
    }
}
