//
//  WorkspaceState.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/30.
//

import Foundation
import Combine


struct WorkspaceState {
    // MARK: - Workspace State
    var workspaces: Loadable<[String: WorkspaceData]> = .notRequested
    
    var allWorkspaces: Loadable<[WorkspaceData]> {
        workspaces.map {
            $0.values.sorted {
                $0.createAt < $1.createAt
            }
        }
    }
    
    var currentWorkspaceID: String?
    {
        willSet(val) {
            members = nil
            channels = .notRequested
            currentChannelID = nil
            currentWeekState = .unknown
            userGambleState = .ready
            csInfo = .init()
            
            // socket
            if let oldWorkspace = currentWorkspace {
                Task {
                    await TrickleWebSocket.shared.leaveRoom(workspaceID: oldWorkspace.workspaceID, memberID: oldWorkspace.userMemberInfo.memberID)
                }
            }
            if let workspaceID = val,
               let newWorkspace = workspaces.value?[workspaceID] {
                Task {
                    await TrickleWebSocket.shared.joinRoom(workspaceID: newWorkspace.workspaceID, memberID: newWorkspace.userMemberInfo.memberID)
                }
            }
        }
    }
    
    var currentWorkspace: WorkspaceData? {
        currentWorkspaceID != nil ? workspaces.value?[currentWorkspaceID!] : nil
    }
    
    var members: [String: MemberData]? = nil
    var allMembers: [MemberData]? {
        guard let members = members else {
            return nil
        }
        return members.values.sorted {
            $0.name.hashValue < $1.name.hashValue
        }
    }
    
    // MARK: - Channel State
    var channels: Loadable<[String: GroupData]> = .notRequested
    
    var allChannels: [GroupData] {
        (channels.value ?? [:]).values.sorted {
            $0.createAt  < $1.createAt
        }
    }
    
    var currentChannelID: String? {
        willSet {
            trickles = .notRequested
            participants = .notRequested
        }
    }
    var currentChannel: Loadable<GroupData> {
        switch channels {
            case .notRequested:
                return .notRequested
            case .isLoading(let last):
                return .isLoading(last: last?[currentChannelID ?? ""])
            case .loaded(let data):
                guard let current = data[currentChannelID ?? ""] else { return .failed(.notFound) }
                return .loaded(data: current)

            case .failed(let error):
                return .failed(error)
        }
    }
    
    
    // MARK: - chanshi State
    var trickles: Loadable<[String: TrickleData]> = .notRequested
    var allTrickles: [TrickleData] {
        switch trickles {
            case .notRequested:
                return []
            case .isLoading(let last):
                return last?.values.sorted {
                    $0.createAt > $1.createAt
                } ?? []
            case .loaded(let data):
                return data.values.sorted {
                    $0.createAt > $1.createAt
                }
            case .failed:
                return []
        }
    }
    
    var latestGamble: TrickleData? {
        TrickleIntergratable.getLatestGameInfo(trickles: allTrickles)
    }
    
    var latestSummary: TrickleData? {
        TrickleIntergratable.getLatestSummary(trickles: allTrickles)
    }
    
    var lastWeekSummary: TrickleData? {
        TrickleIntergratable.getSummary(trickles: allTrickles, week: currentWeek - 1)
    }
    
    var lastWeekSummaryInfo: SummaryInfo? {
        guard let lastWeekSummary = lastWeekSummary else { return nil }
        return TrickleIntergratable.extractSummaryInfo(lastWeekSummary)
    }
    
    var weeklyGambles: [TrickleData] {
        TrickleIntergratable.getWeeklyGambles(allTrickles)
    }
    
    var weeklyGameInfos: [CSUserInfo.GambleInfo] {
        TrickleIntergratable.getWeeklyGambles(allTrickles)
            .compactMap {
                TrickleIntergratable.extractGameInfo($0)
            }
            .sorted {
                $0.score > $1.score
            }
    }
    
    // MARK: - Participant
    var participants: Loadable<[String : MemberData]> = .notRequested
    
    var allParticipants: Loadable<[MemberData]> {
        participants.map {
            $0.values.sorted(by: {
                $0.createAt ?? .distantPast < $1.createAt ?? .distantPast
            })
        }
    }
    
    
    // MARK: - Week State
    enum WeekState {
        case unknown
        case underway
        case finished
        
        var localized: String {
            switch self {
                case .underway:
                    return "进行中"
                case .finished:
                    return "已完成"
                case .unknown:
                    return "未知"
            }
        }
    }
    
//    var lastWeekState: WeekState = .unknown
    var currentWeekState: WeekState = .unknown
    
    // MARK: - User Gamble State
    enum UserGambleState: Equatable {
        case ready
        case played(score: Int)
    }
    
    var userGambleState: UserGambleState = .ready
    
    
    var csInfo: CSUserInfo = .init()
}



enum WorkspaceAction {
    // MARK: - workspace
    case setWorkspaces(items: [WorkspaceData])
    case importWorkspacesToCoreData(items: [WorkspaceData])
    case setWorkspaceMembers(members: [MemberData])
    case setCurrentWorkspace(workspaceID: String?)
    case listWorkspaces(userID: String)
    case listWorkspaceMembers
    
    
    case loadWorkspaces
    
    // MARK: - channel
    case addChannels(items: [GroupData])
    case setChannels(items: [GroupData])
    case createChannel(invitedMemberIDs: [String])
    case listPublicChannels
    
    @available(*, deprecated, message: "Will not be used")
    case listPrivateChannels
    
    // MARK: - chanshi
    case setTrickles(data: Loadable<[String: TrickleData]>)
    case addTrickles(data: [TrickleData])
    case listAllTrickles(until: Int? = nil, loaded: [String : TrickleData] = [:])
    case freshenTrickles
    case createTrickle(payload: TrickleWebRepository.API.CreatePostPayload)
    
    case setParticipants(members: [MemberData])
    case loadParticipants(channelMembers: [MemberData])
    
    case joinCSChannel
    
    case setGameInfo(info: CSUserInfo.GambleInfo?)
    case publishScore(score: Int)
    
    case weekStateCheck
    
    case getUserCSInfo(memberData: MemberData)
    case summarizeIfNeeded
}


let workspaceReducer: Reducer<WorkspaceState, WorkspaceAction, AppEnvironment> = Reducer { state, action, environment in
    switch action {
        case .setWorkspaces(let items):
            state.workspaces = .loaded(data: items.formDictionary(key: \.workspaceID))
            state.channels = .notRequested
            
        case .setWorkspaceMembers(let members):
            state.members = members.formDictionary(key: \.memberID)
            
        case .importWorkspacesToCoreData(let items):
            Task {
                do {
                    try await PersistenceController.shared.importWorkspaces(items)
                } catch {
                    
                }
            }
            
        case .setCurrentWorkspace(let workspaceID):
            state.currentWorkspaceID = workspaceID
        
        case let .listWorkspaces(userID):
            state.workspaces = .isLoading(last: nil)
            return environment.trickleWebRepository
                .listUserWorkspaces(userID: userID)
                .map{ $0.items }
                .replaceError(with: [])
                .map { .setWorkspaces(items: $0) }
                .eraseToAnyPublisher()
            
        case .loadWorkspaces:
            do {
                
            } catch {
                
            }
            break
            
        case .listWorkspaceMembers:
            guard let workspaceID = state.currentWorkspaceID else { break }
            return environment.trickleWebRepository
                .listChannelMembers(workspaceID: workspaceID, channelID: nil)
                .map { $0.items }
                .replaceError(with: [])
                .map { .setWorkspaceMembers(members: $0) }
                .eraseToAnyPublisher()
            
            
        // MARK: - channels
        case .addChannels(let items):
            return Just(.setChannels(items: state.allChannels + items))
                .eraseToAnyPublisher()
            
        case .setChannels(let items):
            state.channels = .loaded(data: items.formDictionary(key: \.groupID))
            state.participants = .notRequested
            
            // get specific channel
            state.currentChannelID = state.channels.value!.values.first {
               $0.name == "Who's shit?"
            }?.groupID
            
        case .createChannel(let invitedMemberIDs):
            guard let workspaceID = state.currentWorkspaceID,
                  let memberID = state.currentWorkspace?.userMemberInfo.memberID else { break }
            return environment.trickleWebRepository
                .createChannel(workspaceID: workspaceID,
                               memberID: memberID,
                               invitedMemberIDs: invitedMemberIDs)
                .map { .addChannels(items: [$0.group]) }
                .catch { _ in
                    Empty()
                }
                .eraseToAnyPublisher()

        case .listPublicChannels:
            state.channels = .isLoading(last: nil)
            guard let workspaceID = state.currentWorkspaceID,
                  let memberID = state.currentWorkspace?.userMemberInfo.memberID else {
                state.channels = .failed(.parameterError)
                break
            }
            return environment.trickleWebRepository
                .listWorkspacePublicChannels(workspaceID: workspaceID, memberID: memberID)
                .map { $0.items }
                .replaceError(with: [])
                .map{
                    .setChannels(items: $0)
                }
                .eraseToAnyPublisher()
            
        case .listPrivateChannels:
            state.channels = .isLoading(last: nil)
            guard let workspaceID = state.currentWorkspaceID,
                  let memberID = state.currentWorkspace?.userMemberInfo.memberID else {
                state.channels = .failed(.parameterError)
                break
            }
            return environment.trickleWebRepository
                .listWorkspacePrivateChannels(workspaceID: workspaceID, memberID: memberID)
                .map { $0.items }
                .replaceError(with: [])
                .map {
                    .setChannels(items: $0)
                }
                .eraseToAnyPublisher()
            
        // MARK: - Trickles
        case .setTrickles(let data):
            state.trickles = data
            
        case .addTrickles(let data):
            state.trickles = .loaded(data: (state.allTrickles + data).formDictionary(key: \.trickleID))
            
        case .listAllTrickles(let until, let loaded):
            if loaded.count > 0 {
                state.trickles = .isLoading(last: loaded)
            }
            guard let workspaceID = state.currentWorkspaceID,
                  let channelID = state.currentChannel.value?.groupID,
                  let memberID = state.currentWorkspace?.userMemberInfo.memberID else {
                state.trickles = .failed(.parameterError)
                break
            }
            print(channelID, until ?? 0)
            return environment.trickleWebRepository
                .listPosts(workspaceID: workspaceID,
                           query: .init(workspaceID: workspaceID, receiverID: channelID, memberID: memberID, until: until, limit: 40))
                .retry(3)
                .flatMap { streamable in
                    if let nextTS = streamable.nextTs {
                        return Just(WorkspaceAction.addTrickles(data: streamable.items))
                            .flatMap { _ in
                                Just(WorkspaceAction.listAllTrickles(until: nextTS))
                            }
                            .eraseToAnyPublisher()
                    } else {
                        return Just(WorkspaceAction.addTrickles(data: streamable.items))
                            .eraseToAnyPublisher()
                    }
                }
                .catch { Just(WorkspaceAction.setTrickles(data: .failed(.unexpected(error: $0)))) }
                .eraseToAnyPublisher()
            
        case .freshenTrickles:
            /// 从第一个不是自己的post开始刷
            guard case .loaded = state.trickles,
                  let workspaceID = state.currentWorkspaceID,
                  let channelID = state.currentChannel.value?.groupID,
                  let memberID = state.currentWorkspace?.userMemberInfo.memberID,
                  let nextTs = Int(state.allTrickles
                    .first(where: { $0.authorMemberInfo.memberID != memberID })?
                    .createAt.timeIntervalSince1970) else {
                break
            }
            
            return environment.trickleWebRepository
                .listPosts(workspaceID: workspaceID,
                           query: .init(workspaceID: workspaceID,
                                        receiverID: channelID,
                                        memberID: memberID,
                                        until: nextTs,
                                        limit: 100,
                                        order: 1))
                .retry(3)
                .map {
                    .addTrickles(data: $0.items)
                }
                .catch { _ in
                    Empty()
                }
                .eraseToAnyPublisher()
            
            
        case .createTrickle(let payload):
            guard let workspaceID = state.currentWorkspaceID,
                  let channelID = state.currentChannel.value?.groupID,
                  let memberID = state.currentWorkspace?.userMemberInfo.memberID else {
                break
            }
            return environment.trickleWebRepository
                .createPost(workspaceID: workspaceID,
                            channelID: channelID,
                            payload: payload)
                .map {
                    .addTrickles(data: [$0])
                }
                .catch { _ in
                    Empty()
                }
                .eraseToAnyPublisher()
                
            
        case .setParticipants(let members):
            state.participants = .loaded(data: members.formDictionary(key: \.memberID))
            
        case .loadParticipants(let channelMembers):
            guard state.trickles.state == .loaded else { break }
            state.participants = .isLoading(last: state.participants.value)
            
            let posts = state.allTrickles.filter { trickle in
                TrickleIntergratable.getType(trickle.blocks) == .helloWorld
            }
            var uniqueMemberIDs = Set<String>()
            for post in posts {
                uniqueMemberIDs.insert(post.authorMemberInfo.memberID)
            }
            let participants: [MemberData] = channelMembers.filter {
                uniqueMemberIDs.contains($0.memberID)
            }
            state.participants = .loaded(data: participants.formDictionary(key: \.memberID))
            
        case .joinCSChannel:
            guard let workspaceID = state.currentWorkspaceID,
                  let channelID = state.currentChannel.value?.groupID,
                  let memberID = state.currentWorkspace?.userMemberInfo.memberID else {
                break
            }
            return Just(.createTrickle(payload: .init(authorMemberID: memberID,
                                                      blocks: TrickleIntergratable.createPost(type: .helloWorld),
                                                      mentionedMemberIDs: [])))
            .eraseToAnyPublisher()
            
        case .setGameInfo(let info):
            state.csInfo.roundGame = info
            
        case .publishScore(let score):
            guard let workspaceID = state.currentWorkspaceID,
                  let channelID = state.currentChannel.value?.groupID,
                  let memberID = state.currentWorkspace?.userMemberInfo.memberID else {
                break
            }
            return  Just(.createTrickle(payload: .init(authorMemberID: memberID,
                                                       blocks: TrickleIntergratable.createPost(type: .gamble(score: score)))))
            .eraseToAnyPublisher()
            
            
        case .weekStateCheck:
            func setAsFinishedWeek() {
                state.currentWeekState = .finished
            }
            
            func setAsUnderwayWeek() {
                state.currentWeekState = .underway
            }
            
            guard state.trickles.state == .loaded else { break }
            
            guard state.latestGamble != nil else {
                /// 初始周
                setAsUnderwayWeek()
                break
            }
            
            var weekDiff = 0
            if let latestSummary = state.latestSummary {
                // TODO: 123 -
                guard let latestSummaryWeek = TrickleIntergratable.extractSummaryInfo(latestSummary)?.week else {
                    setAsUnderwayWeek()
                    break
                }
                guard latestSummaryWeek < currentWeek else {
                    setAsFinishedWeek()
                    break
                }
                weekDiff = currentWeek - latestSummaryWeek - 1
            } else {
                let firstGambleWeek = getWeek(second: TrickleIntergratable.getEarliestGameInfo(trickles: state.allTrickles)!.createAt)
                weekDiff = currentWeek - firstGambleWeek
            }
            
            setAsUnderwayWeek()
            
            guard let workspaceID = state.currentWorkspaceID,
                  let channelID = state.currentChannel.value?.groupID,
                  let memberID = state.currentWorkspace?.userMemberInfo.memberID,
                  state.trickles.state == .loaded,
                  case .loaded = state.allParticipants,
                  let allParticipants = state.allParticipants.value,
                  weekDiff > 0 else {
                break
            }
            
            // TODO: publish summary
            let summaryPublishers: [AnyPublisher<WorkspaceAction, Never>] = (0..<weekDiff).map { i  in
                let week = currentWeek - weekDiff + i
                
                let gameInfos = TrickleIntergratable.getWeeklyGameInfos(state.allTrickles, week: week)
                let playeds = gameInfos.map { $0.memberData.memberID }
                let absentees = allParticipants.filter {
                    !playeds.contains($0.memberID)
                }
                
                let memberAndScores = gameInfos.map {
                    ($0.memberData, $0.score)
                } + absentees.map {
                    ($0, nil)
                }.shuffled()
                
                return environment.trickleWebRepository.createPost(workspaceID: workspaceID, channelID: channelID,
                                                                   payload: .init(authorMemberID: memberID,
                                                                                  blocks: TrickleIntergratable.createPost(type: .summary(week,
                                                                                                                                         memberAndScores: memberAndScores))))
                
                .map {
                    .addTrickles(data: [$0])
                }
                .catch { _ in
                    Empty()
                }
                .eraseToAnyPublisher()
            }
            
            return Publishers.MergeMany(summaryPublishers)
                .eraseToAnyPublisher()

            
        case .getUserCSInfo:
            guard let memberData = state.currentWorkspace?.userMemberInfo else {
                 break
            }
            guard state.trickles.state == .loaded else { break }
            
            switch state.currentWeekState {
                case .underway:
                    let latestUserGamble = state.allTrickles.first {
                        if case .gamble = TrickleIntergratable.getType($0.blocks),
                           $0.authorMemberInfo.memberID == memberData.memberID { return true }
                        return false
                    }
                    
                    guard let latestUserGamble = latestUserGamble else { break }
                    
                    let latestUserGambleWeek = getWeek(second: latestUserGamble.createAt)
                    
                    if latestUserGambleWeek == currentWeek {
                        var gameInfo = TrickleIntergratable.extractGameInfo(latestUserGamble)
                        TrickleIntergratable.updateGambleRank(&gameInfo, allTrickles: state.allTrickles)
                        state.csInfo.roundGame = gameInfo
                    } else {
                        state.csInfo.roundGame = nil
                    }
                case .finished:
                    guard let summaryTrickle = state.latestSummary else { break }
                    guard let userGameInfo = TrickleIntergratable.getUserGameInfo(from: summaryTrickle, userMemberData: memberData) else {
                        state.csInfo.roundGame = nil
                        break
                    }
                    state.csInfo.roundGame = userGameInfo
                    
                case .unknown:
                    state.csInfo.roundGame = nil
            }

        case .summarizeIfNeeded:
            guard let workspaceID = state.currentWorkspaceID,
                  let channelID = state.currentChannel.value?.groupID,
                  let memberID = state.currentWorkspace?.userMemberInfo.memberID,
                  state.trickles.state == .loaded,
                  case .loaded = state.allParticipants else {
                break
            }
            
            let gameInfos = TrickleIntergratable.getWeeklyGameInfos(state.allTrickles)
            
            guard gameInfos.count == state.allParticipants.value?.count ?? 0 else {
                break
            }
            
            return Just(WorkspaceAction
                .createTrickle(payload: .init(authorMemberID: memberID,
                                              blocks: TrickleIntergratable
                    .createPost(type: .summary(memberAndScores: gameInfos.map {
                        ($0.memberData, $0.score)
                    })))))
            .flatMap { _ in
                return Just(.freshenTrickles).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    return Empty().eraseToAnyPublisher()
}



struct WorkspaceData: Codable, Hashable {
    let workspaceID: String
    let ownerID, name: String
    let memberNum, removedMemberNum: Int
    let logo, domain: String
    let userID: String
    let createAt, updateAt: Date
    let userMemberInfo: MemberData
    
    enum CodingKeys: String, CodingKey {
        case workspaceID = "workspaceId"
        case ownerID = "ownerId"
        case name, memberNum, removedMemberNum, logo, domain
        case userID = "userId"
        case createAt, updateAt, userMemberInfo
    }
}

extension WorkspaceData: Identifiable {
    var id: String {
        workspaceID
    }
}


// MARK: - GroupData
struct GroupData: Codable, Equatable {
    let name, groupID, ownerID: String
    let isGeneral, isWorkspacePublic: Bool?
    let createAt, updateAt: Date

    enum CodingKeys: String, CodingKey {
        case name
        case groupID = "groupId"
        case ownerID = "ownerId"
        case isGeneral, isWorkspacePublic, createAt, updateAt
    }
}

struct GroupDataWrapper: Codable {
    let group: GroupData
}



// MARK: - MemberData
struct MemberData: Codable, Hashable {
    let name, role, status, memberID, avatarURL: String
    let email: String?
    let createAt, updateAt: Date?

    enum CodingKeys: String, CodingKey {
        case name, role, email, status
        case memberID = "memberId"
        case avatarURL = "avatarUrl"
        case createAt, updateAt
    }
}


// MARK: - TrickleData
struct TrickleData: Codable, Equatable {
    let trickleID: String
    let authorMemberInfo: MemberData
//    let receiverInfo: ReceiverInfo
    let createAt, updateAt: Date
    let editAt: Date?
    let title: String
    let blocks: [Block]
//    let tagInfo, mentionedMemberInfo: [JSONAny]
//    let isPublic, allowGuestMemberComment, allowGuestMemberReact, allowWorkspaceMemberComment: Bool
//    let allowWorkspaceMemberReact: Bool
//    let likeCounts, commentCounts: Int
//    let hasLiked: Bool
//    let latestLikeMemberInfo, commentInfo, referTrickleInfo, reactionInfo: [JSONAny]
//    let viewedMemberInfo: ViewedMemberInfo
//    let threadID: JSONNull?

    enum CodingKeys: String, CodingKey {
        case trickleID = "trickleId"
        case authorMemberInfo, createAt, updateAt, editAt, title, blocks
//        , isPublic, allowGuestMemberComment, allowGuestMemberReact, allowWorkspaceMemberComment, allowWorkspaceMemberReact, likeCounts, commentCounts, hasLiked
//        case receiverInfo, tagInfo, latestLikeMemberInfo, viewedMemberInfo, commentInfo, referTrickleInfo, reactionInfo,
//        case threadID = "threadId"
    }
}
