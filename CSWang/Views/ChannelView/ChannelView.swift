//
//  ChannelView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/2.
//

import SwiftUI

enum CSInfo: String, CaseIterable {
    case immunityNum
    case lastCleanDate
    case nextCleanDate

    var localized: String {
        switch self {
            case .immunityNum:
                return "豁免权"
            case .lastCleanDate:
                return "上一次铲屎时间"
            case .nextCleanDate:
                return "下一次铲屎时间"
        }
    }
}

extension CSInfo: Identifiable {
    var id: String {
        return self.rawValue
    }
}

struct ChannelView: View {
    @EnvironmentObject var store: AppStore
    
    var workspace: WorkspaceData? {
        store.state.workspace.currentWorkspace
    }
    
    var channel: Loadable<GroupData> {
        store.state.workspace.channel.currentChannel
    }
    
    var memberInfo: MemberData? {
        workspace?.userMemberInfo
    }
    
    var body: some View {
        content
    }
    
    
    @ViewBuilder private var content: some View {
        switch channel {
            case .notRequested:
                notRequestedView
            case .isLoading(let last):
                loadingView(last)
            case .loaded(let data):
                switch store.state.workspace.channel.chanshi.userChannelState {
                    case .notJoined:
                        joinChannelView()
                    case .joined:
                        loadedView(data)
                    case .checking:
                        loadingView(nil)
                            .onAppear(perform: checkUserChannelState)
                }
            case .failed(let error):
                failedView(error)
        }
       
    }
}

//MARK: - Side Effects
private extension ChannelView {
    private func checkUserChannelState() {
        guard let workspace = workspace,
              let channel = channel.value,
              let member = memberInfo else { return }
        Task {
            await store.send(.chanshi(action: .checkHasJoined(workspaceID: workspace.workspaceID,
                                                              channelID: channel.groupID,
                                                              memberID: member.memberID)))
        }
    }
    
    private func joinChannel() async {
        guard let workspace = workspace,
              let channel = channel.value,
              let member = memberInfo else { return }
        await store.send(.chanshi(action: .joinCSChannel(workspaceID: workspace.workspaceID,
                                                         channelID: channel.groupID,
                                                         memberID: member.memberID)))
    }
}


// MARK: - Loading Content
private extension ChannelView {
    var notRequestedView: some View {
        Text("No data")
    }
    
    func loadingView(_ previouslyLoaded: GroupData?) -> some View {
        VStack {
            LoadingView { _ in
                Text("Loading...")
            }
        }
    }
    
    func failedView(_ error: LoadableError) -> some View {
        @ViewBuilder var errorView: some View {
            switch error {
                case .notFound:
                    CreateChannelView()
                    
                default:
                    ErrorView(error: error) {
                        
                    }
            }
        }
        return errorView
    }
}

// MARK: - Displaying Content
extension ChannelView {
    func loadedView(_ data: GroupData) -> some View {
        NavigationStack {
            VStack {
                AvatarView(url: URL(string: memberInfo?.avatarURL ?? ""),
                           fallbackText: String(memberInfo?.name.prefix(2) ?? ""),
                           size: 80)
                
                Text(memberInfo?.name ?? "Unknown")
                    .font(.title)
                    .fontWeight(.bold)
                List {
                    ForEach(CSInfo.allCases) { info in
                        HStack {
                            Text(info.localized)
                            Spacer()
                            Text("0")
                        }
                    }
                }
                Spacer()
                
            }
            .navigationTitle(workspace?.name ?? "")
            .toolbar {
                NavigationLink {
                    ParticipantsView()
                } label: {
                    Image(systemName: "person.2")
                }
                .disabled(channel.value == nil)
            }
        }
    }
    
    func joinChannelView() -> some View {
        VStack {
            Text("It seems that there is already a channel.")
            Button {
                Task {
                    await joinChannel()
                }
            } label: {
                Text("Join")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}

struct ChannelView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelView()
            .environmentObject(AppStore.preview)
    }
}
