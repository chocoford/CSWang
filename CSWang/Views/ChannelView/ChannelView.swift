//
//  ChannelView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/2.
//

import SwiftUI
import Charts

struct ChannelView: View {
    @EnvironmentObject var store: AppStore
    
    var workspaceState: WorkspaceState {
        store.state.workspace
    }
    
    var workspace: WorkspaceData? {
        workspaceState.currentWorkspace
    }
    
    var channel: Loadable<GroupData?> {
        workspaceState.currentChannel
    }
    
    var memberInfo: MemberData? {
        workspace?.userMemberInfo
    }

    @State private var freshingTrickles = false
    
    // MARK: - User Channel State
    enum UserChannelState {
        case joined
        case notJoined
        case checking
    }
    var userChannelState: UserChannelState {
        guard workspaceState.trickles.state == .loaded else { return .checking }
        if workspaceState.trickles.value?.values.first(where: {
            return TrickleIntergratable.getType($0.blocks) == .helloWorld && $0.authorMemberInfo.memberID == memberInfo?.memberID
        }) != nil {
            return .joined
        }
        return .notJoined
    }
    
    
    var body: some View {
        content
    }
    
    @State private var showGameView = false
    
    @ViewBuilder private var content: some View {
        switch channel {
            case .notRequested:
                notRequestedView
            case .isLoading(let last):
                if let last = last {
                    loadingView(last)
                } else {
                    loadingView(nil)
                }
            case .loaded(let data):
                if let data = data {
                    channelView(data)
                } else {
                    CreateChannelView()
                }
            case .failed(let error):
                failedView(error)
        }
    }
    
    @ViewBuilder func channelView(_ channel: GroupData) -> some View {
        switch workspaceState.trickles {
            case .notRequested:
                fetchingView()
                    .onAppear(perform: loadAllPosts)
            case .isLoading:
                fetchingView()
            case .loaded:
                switch userChannelState {
                    case .notJoined:
                        JoinChannelView()
                    case .joined:
                        loadedView(channel)
                            .onAppear(perform: getChanShiInfo)
                            .onReceive(TrickleWebSocket.shared.changeNotifyPulisher) { _ in
                                freshenPosts()
                            }
                            .onChange(of: store.state.workspace.members) { newValue in
                                Task {
                                    await store.send(.workspace(action: .loadParticipants(channelMembers: store.state.workspace.allMembers ?? [])))
                                }
                            }
                    case .checking:
                        loadingView(nil)
                }
            case .failed(let error):
                failedView(error)
        }
    }
}

//MARK: - Side Effects
private extension ChannelView {
    private func getChanShiInfo() {
        guard let member = memberInfo else { return }
        Task {
            await store.send(.workspace(action: .loadParticipants(channelMembers: store.state.workspace.allMembers ?? [])))
            await store.send(.workspace(action: .weekStateCheck))
            await store.send(.workspace(action: .getUserCSInfo(memberData: member)))
        }
    }
    
    private func loadAllPosts() {
        Task {
            await store.send(.workspace(action: .listAllTrickles()))
            await store.send(.workspace(action: .loadParticipants(channelMembers: store.state.workspace.allMembers ?? [])))
        }
    }
    
    private func freshenPosts() {
        Task {
            freshingTrickles = true
            await store.send(.workspace(action: .freshenTrickles))
            getChanShiInfo()
            freshingTrickles = false
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
            ErrorView(error: error) {
                
            }
        }
        return errorView
    }
}

// MARK: - Displaying Content
extension ChannelView {
    func loadedView(_ data: GroupData) -> some View {
        @ViewBuilder var body: some View {
            VStack {
                VStack {
                    Text("Week \(currentWeek)")
                        .font(.largeTitle)
                        .fontWeight(.black)
                    
                    Text("?????????\(workspaceState.currentWeekState.localized)")
                    if let summary = workspaceState.lastWeekSummaryInfo,
                       let index = Array(summary.rankedParticipantIDsAndScores.reversed().prefix(5)).firstIndex(where: {$0.0 == memberInfo?.memberID}) {
                        Text("Your chanshi date???\(getWeekDayName(index: index))")
                    }
                    
                }
                .padding(.vertical)
                ScrollView {
                    gameInfoView
                }
            }
            .padding(.horizontal)
            .navigationTitle(workspace?.name ?? "")
            .toolbar {
                HStack {
                    if freshingTrickles {
                        LoadingView(size: 16, lineWidth: 2)
                    }
                
                    NavigationLink {
                        ParticipantsView()
                            .navigationTitle("Participants")
                    } label: {
                        Image(systemName: "person.2")
                    }
                    .disabled(channel.value == nil)
                }
            }
        }
        
        if #available(iOS 16.0, *), #available(macOS 13.0, *) {
            return NavigationStack {
                body
            }
        } else {
            return body
        }
    }
}

private extension ChannelView {
    @ViewBuilder var dutyView: some View {
        VStack(alignment: .leading) {
            Text("Last Week Info")
                .font(.subheadline)
                .foregroundColor(.gray)
            HStack {
                Spacer()
                GameInfoCard(title: "Rank", content: "-")
                Spacer()
                Divider()
                Spacer()
                GameInfoCard(title: "Chanshi Date", content: "-")
                Spacer()
            }
            .padding()
            .background(.ultraThickMaterial)
            .containerShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Components: Game Info View
private extension ChannelView {
    func GameInfoCard(title: String, content: String) -> some View {
        VStack {
            Text(title)
            Text(content)
                .font(.title)
                .fontWeight(.bold)
                .padding(6)
        }
    }
    
    @ViewBuilder var gameInfoRow: some View {
        VStack(alignment: .leading) {
            Text("Game")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                Spacer()
                GameInfoCard(title: "Score", content: workspaceState.csInfo.roundGame != nil ? "\(workspaceState.csInfo.roundGame!.score)" : "-")
                Spacer()
                Divider()
                Spacer()
                GameInfoCard(title: "Rank", content: "\(workspaceState.csInfo.roundGame?.rank != nil ? (workspaceState.csInfo.roundGame!.rank! + 1).formatted() : "-")")
                Spacer()
            }
            .padding()
            .background(.ultraThickMaterial)
            .if(workspaceState.csInfo.roundGame == nil, transform: { content in
                content
                    .blur(radius: 4)
                    .background(.ultraThickMaterial)
                    .overlay {
                        Button {
                            showGameView = true
                        } label: {
                            Text("Play")
                        }
                        .buttonStyle(PrimaryButtonStyle(disabled: workspaceState.currentWeekState == .finished))
                        .shadow(radius: 4)
                        .disabled(workspaceState.currentWeekState == .finished)
                    }
            })
                .containerShape(RoundedRectangle(cornerRadius: 8))
                .sheet(isPresented: $showGameView) {
                GameView(show: $showGameView)
                    .padding()
            }
        }
    }
    
    @ViewBuilder var rankChartView: some View {
        if #available(iOS 16.0, *), #available(macOS 13.0, *) {
            Chart(workspaceState.weeklyGameInfos, id: \.memberData) {
                BarMark(x: .value("score", $0.score), y: .value("participant", $0.memberData.name))
            }
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder var gameInfoView: some View {
        VStack {
            gameInfoRow
            rankChartView
        }
    }
}

// MARK: - Components: Properties(??????) View
private extension ChannelView {
//    Section {
//        Text("???????????????")
//    } header: {
//        Text("??????")
//    }
//    
//    Section {
//        Text("??????????????????")
//        Text("?????????????????????")
//    } header: {
//        Text("??????")
//    }
}

#if DEBUG
struct ChannelView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelView()
            .environmentObject(AppStore.preview)
    }
}
#endif
