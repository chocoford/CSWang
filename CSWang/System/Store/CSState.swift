//
//  CSState.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/6.
//

import Foundation
import Combine
import OSLog

struct CSState {
    var participants: Loadable<[String : MemberData]> = .notRequested
    
    var allParticipants: Loadable<[MemberData]> {
        switch participants {
            case .notRequested:
                return .notRequested
            case .isLoading(let last):
                let last: [MemberData] = (last ?? [:]).values.sorted(by: {
                    $0.createAt ?? 0 < $1.createAt ?? 0
                })
                return .isLoading(last: last)
            case .loaded(let data):
                return .loaded(data: data.values.sorted(by: {
                    $0.createAt ?? 0 < $1.createAt ?? 0
                }))
            case .failed(let error):
                return .failed(error)
        }
    }
    
    enum UserChannelState {
        case joined
        case notJoined
        case checking
    }
    var userChannelState: UserChannelState = .checking
    
    enum WeekState {
        case unknown
        case underway
        case finished
    }
    
    var lastWeekState: WeekState = .unknown
    var currentWeekState: WeekState = .unknown
    
    
    var csInfo: CSUserInfo = .init()
}

enum CSAction {
    case setParticipants(members: [MemberData])
    case loadParticipants(workspaceID: String, channelID: String, memberID: String, channelMembers: [MemberData])
    
    case setUserChannelState(_ state: CSState.UserChannelState)
    case joinCSChannel(workspaceID: String, channelID: String, memberID: String)
    case checkHasJoined(workspaceID: String, channelID: String, memberID: String)
    
    case setGameInfo(info: Loadable<CSUserInfo.GambleInfo?>)
    case publishScore(workspaceID: String, channelID: String, memberID: String, score: Int)
    
    case initailWeekCheck(workspaceID: String, channelID: String, memberID: String)
    case getUserLatestGameInfo(workspaceID: String, channelID: String, memberID: String)
    case getLatestSummary(workspaceID: String, channelID: String, memberID: String)
}

//let csReducer: Reducer<CSState, AppAction, AppEnvironment> = Reducer { state, action, environment in
func csReducer(state: inout CSState,
               action: CSAction,
               environment: AppEnvironment) -> AnyPublisher<AppAction, Never> {
    let logger = Logger(subsystem: "CSWang", category: "chanshiReducer")
    switch action {
        case .setParticipants(let members):
            state.participants = .loaded(data: members.formDictionary(key: \.memberID))
            
        case .loadParticipants(let workspaceID, let channelID, let memberID, let channelMembers):
            state.participants = .isLoading(last: state.participants.value)
            return environment.trickleWebRepository
                .listPosts(workspaceID: workspaceID,
                           query: .init(workspaceID: workspaceID,
                                        receiverID: channelID,
                                        memberID: memberID,
                                        limit: 10))
                .retry(3)
                .replaceError(with: .init(items: [], nextTs: nil))
                .map { streamable in
                    let posts = streamable.items.filter { trickle in
                        TrickleIntergratable.getType(trickle.blocks) == .helloWorld
                    }
                    var uniqueMemberIDs = Set<String>()
                    for post in posts {
                        uniqueMemberIDs.insert(post.authorMemberInfo.memberID)
                    }
                    let participants: [MemberData] = channelMembers.filter {
                        uniqueMemberIDs.contains($0.memberID)
                    }
                    return .chanshi(action: .setParticipants(members: participants))
                }
                .eraseToAnyPublisher()
            
        case .setUserChannelState(let channelState):
            state.userChannelState = channelState
            
        case .checkHasJoined(let workspaceID, let channelID, let memberID):
            return environment.trickleWebRepository
                .listPosts(workspaceID: workspaceID, query: .init(workspaceID: workspaceID,
                                                                  receiverID: channelID,
                                                                  memberID: memberID,
                                                                  authorID: memberID))
                .map {
                    let hasHelloWorld = $0.items.first {
                        TrickleIntergratable.getType($0.blocks) == .helloWorld
                    }
                    if hasHelloWorld != nil {
                        return .chanshi(action: .setUserChannelState(.joined))
                    } else {
                        return .chanshi(action: .setUserChannelState(.notJoined))
                    }
                }
                .catch { _ in
                    return Empty()
                }
                .eraseToAnyPublisher()
            
        case .joinCSChannel(let workspaceID, let channelID, let memberID):
            return environment.trickleWebRepository
                .createPost(workspaceID: workspaceID,
                            channelID: channelID,
                            payload: .init(authorMemberID: memberID,
                                           blocks: TrickleIntergratable.createPost(type: .helloWorld),
                                           mentionedMemberIDs: []))
                .map { _ in
                        .chanshi(action: .setUserChannelState(.checking))
                }
                .catch {
                    logger.error("\($0)")
                    return Just(AppAction.chanshi(action: .setUserChannelState(.notJoined)))
                }
                .eraseToAnyPublisher()
            
        case .setGameInfo(let info):
            state.csInfo.roundGame = info
            
        case .publishScore(let workspaceID, let channelID, let memberID, let score):
            return environment.trickleWebRepository
                .createPost(workspaceID: workspaceID,
                            channelID: channelID,
                            payload: .init(authorMemberID: memberID,
                                           blocks: TrickleIntergratable.createPost(type: .gamble(score: score))))
                .map { _ in
                        .chanshi(action: .setUserChannelState(.checking))
                }
                .catch {
                    logger.error("\($0)")
                    return Just(AppAction.chanshi(action: .setUserChannelState(.notJoined)))
                }
                .eraseToAnyPublisher()
            
        case .initailWeekCheck(let workspaceID, let channelID, let memberID):
            break
//            return environment.trickleWebRepository
//                .listPosts(workspaceID: workspaceID,
//                           query: .init(workspaceID: workspaceID,
//                                        receiverID: channelID,
//                                        memberID: memberID))
//                .map {
//                    if $0.items.contains(where: {
//                        TrickleIntergratable.getType($0.blocks) == .gamble(score: 0)
//                    }) {
//                        /// Check last week is finished or not.
//                        return .chanshi(action: .getLatestSummary(workspaceID: workspaceID, channelID: channelID, memberID: memberID))
//                    } else {
//                        state.lastWeekState = .finished
//                        state.currentWeekState = .underway
//                    }
//                    return AppAction.nap
//                }
//                .catch { _ in
//                    return Just(AppAction.nap)
//                }
//                .eraseToAnyPublisher()
            
        case .getUserLatestGameInfo(let workspaceID, let channelID, let memberID):
//            return environment.trickleWebRepository
//                .listPosts(workspaceID: workspaceID, query: .init(workspaceID: workspaceID,
//                                                                  receiverID: channelID,
//                                                                  memberID: memberID,
//                                                                  authorID: memberID))
//                .map {
//                    guard let post: TrickleData = $0.items.first(where: {
//                        return TrickleIntergratable.getType($0.blocks)?.id == TrickleIntergratable.PostType.gamble(score: 0).id
//                    }) else {
//                        return .nap
//                    }
//                    guard let gameInfo = TrickleIntergratable.extractGameInfo(post.blocks) else {
//                        return .nap
//                    }
//
//                    if gameInfo.weekNum == currentWeek {
//                        return .chanshi(action: .setGameInfo(info: .loaded(data: .init(weekNum: gameInfo.weekNum,
//                                                                                                score: gameInfo.score,
//                                                                                                rank: nil,
//                                                                                                absent: false,
//                                                                                                isValid: true))))
//                    } else {
//                        return .chanshi(action: .setCsInfo(info: .loaded(data: nil)))
//                    }
//                }
//                .catch { _ in
//                    return Just(.nap)
//                }
//                .eraseToAnyPublisher()
            break
        
        case .getLatestSummary(let workspaceID, let channelID, let memberID):
            break
//            return environment.trickleWebRepository
//                .listPosts(workspaceID: workspaceID,
//                           query: .init(workspaceID: workspaceID,
//                                        receiverID: channelID,
//                                        memberID: memberID,
//                                        limit: 20))
//                .map {
//                    if let summaryInfo = TrickleIntergratable.getLatestSummary(trickles: $0.items) {
//                        if summaryInfo.week == currentWeek {
//                            state.currentWeekState = .finished
//                            state.lastWeekState = .finished
//                        } else if summaryInfo.week == currentWeek - 1 {
//                            state.currentWeekState = .underway
//                            state.lastWeekState = .finished
//                        } else {
//                            // 依次补发
//                        }
//                    } else {
//
//                    }
//                    return .nap
//                }
//                .catch({ _ in
//                    return Just(.nap)
//                })
//                .eraseToAnyPublisher()
    }
    
    
    return Empty().eraseToAnyPublisher()
}
