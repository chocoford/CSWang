//
//  ChannelView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/2.
//

import SwiftUI

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
    
    var csState: CSState {
        store.state.workspace.channel.chanshi
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
                switch store.state.workspace.channel.chanshi.trickles {
                    case .notRequested:
                        fetchingView()
                            .onAppear(perform: loadAllPosts)
                    case .isLoading:
                        fetchingView()
                    case .loaded:
                        switch store.state.workspace.channel.chanshi.userChannelState {
                            case .notJoined:
                                joinChannelView()
                            case .joined:
                                loadedView(data)
                                    .onAppear(perform: getChanShiInfo)
                            case .checking:
                                loadingView(nil)
                                    .onAppear(perform: checkUserChannelState)
                        }
                    case .failed(let error):
                        failedView(error)
                }
            case .failed(let error):
                failedView(error)
        }
       
    }
}

//MARK: - Side Effects
private extension ChannelView {
    private func checkUserChannelState() {
        guard let member = memberInfo else {
            return
        }
        Task {
            await store.send(.chanshi(action: .checkHasJoined(memberID: member.memberID)))
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
    
    private func getChanShiInfo() {
        guard let member = memberInfo else { return }
        Task {
            await store.send(.chanshi(action: .weekStateCheck))
            await store.send(.chanshi(action: .getUserCSInfo(memberID: member.memberID)))
        }
    }
    
    private func loadAllPosts() {
        guard let workspace = workspace,
              let channel = channel.value,
              let member = memberInfo else { return }
        Task {
            await store.send(.chanshi(action: .listAllTrickles(workspaceID: workspace.workspaceID,
                                                               channelID: channel.groupID,
                                                               memberID: member.memberID)))
            
            await store.send(.chanshi(action: .loadParticipants(channelMembers: store.state.workspace.allMembers ?? [])))
        }
    }
    
    private func gamble() async {
        guard let workspace = workspace,
              let channel = channel.value,
              let member = memberInfo else { return }
        
        if case .ready = csState.userGambleState {
            let score = Int.random(in: 0..<100)
            await store.send(.chanshi(action: .publishScore(workspaceID: workspace.workspaceID,
                                                            channelID: channel.groupID,
                                                            memberID: member.memberID,
                                                            score: score)))
            await store.send(.chanshi(action: .getUserCSInfo(memberID: member.memberID)))
            await store.send(.chanshi(action: .summarizeIfNeeded(workspaceID: workspace.workspaceID,
                                                                 channelID: channel.groupID,
                                                                 memberID: member.memberID)))
            await store.send(.chanshi(action: .weekStateCheck))
        }

    }
}


// MARK: - Loading Content
private extension ChannelView {
    var notRequestedView: some View {
        Text("No data")
    }
    
    func fetchingView() -> some View {
        VStack {
            LoadingView { _ in
                Text("Fetching data...")
            }
        }
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
                Text("Week \(currentWeek)")
                    .font(.largeTitle)
                    .fontWeight(.black)
                
                Text("状态：\(csState.currentWeekState.localized)")
                
                List {
                    Section {
                        HStack {
                            Text("铲屎状态")
                            Spacer()
                            if let gameInfo = csState.csInfo.roundGame {
                                Text("得分：\(gameInfo.score)")
                            } else {
                                Text("未得分")
                            }
                        }
                        Button {
                            Task {
                                await gamble()
                            }
                        } label: {
                            Text("Play")
                        }
                    } header: {
                        Text("本周铲屎信息")
                    }
                    
                    Section {
                        Text("豁免权数量")
                    } header: {
                        Text("资产")
                    }
                    
                    Section {
                        Text("累计铲屎次数")
                        Text("总铲屎数量排名")
                    } header: {
                        Text("记录")
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
