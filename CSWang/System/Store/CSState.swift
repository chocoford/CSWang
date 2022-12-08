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
    var trickles: Loadable<[String: TrickleData]> = .notRequested
    var allTrickles: [TrickleData] {
        switch trickles {
            case .notRequested:
                return []
            case .isLoading(let last):
                return last?.values.sorted {
                    $0.createAt < $1.createAt
                } ?? []
            case .loaded(let data):
                return data.values.sorted {
                    $0.createAt < $1.createAt
                }
            case .failed:
                return []
        }
    }
    
    var latestGamble: TrickleData? {
        allTrickles.first {
            if case .gamble = TrickleIntergratable.getType($0.blocks) {
                return true
            }
            return false
        }
    }
    
    var latestSummary: TrickleData? {
        allTrickles.first {
            if case .summary = TrickleIntergratable.getType($0.blocks) {
                return true
            }
            return false
        }
    }
    
    // MARK: - Participant
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
    
    // MARK: - User Channel State
    enum UserChannelState {
        case joined
        case notJoined
        case checking
    }
    var userChannelState: UserChannelState = .checking
    
    
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
    
    var lastWeekState: WeekState = .unknown
    var currentWeekState: WeekState = .unknown
    
    // MARK: - User Gamble State
    enum UserGambleState: Equatable {
        case ready
        case played(score: Int)
    }
    
    var userGambleState: UserGambleState = .ready
    
    
    var csInfo: CSUserInfo = .init()
}

enum CSAction {
    case setTrickles(data: Loadable<[String: TrickleData]>)
    case listAllTrickles(workspaceID: String, channelID: String, memberID: String, until: Int? = nil)
    
    case setParticipants(members: [MemberData])
    case loadParticipants(channelMembers: [MemberData])
    
    case setUserChannelState(_ state: CSState.UserChannelState)
    case joinCSChannel(workspaceID: String, channelID: String, memberID: String)
    case checkHasJoined(memberID: String)
    
    case setGameInfo(info: Loadable<CSUserInfo.GambleInfo?>)
    case publishScore(workspaceID: String, channelID: String, memberID: String, score: Int)
    
    case weekStateCheck
    
    case getUserLatestGameInfo(workspaceID: String, channelID: String, memberID: String)
    case getLatestSummary
}

//let csReducer: Reducer<CSState, AppAction, AppEnvironment> = Reducer { state, action, environment in
func csReducer(state: inout CSState,
               action: CSAction,
               environment: AppEnvironment) -> AnyPublisher<AppAction, Never> {
    let logger = Logger(subsystem: "CSWang", category: "chanshiReducer")
    switch action {
        case .setTrickles(let data):
            state.trickles = data
        
        case .listAllTrickles(let workspaceID, let channelID, let memberID, let until):
            return environment.trickleWebRepository
                .listPosts(workspaceID: workspaceID,
                           query: .init(workspaceID: workspaceID, receiverID: channelID, memberID: memberID, until: until, limit: 40))
                .retry(3)
                .map { [state] streamable -> AppAction in
                    let result = (state.trickles.value ?? [:]) + streamable.items.formDictionary(key: \.trickleID)
                    if let nextTS = streamable.nextTs {
                        _ = AppAction.chanshi(action: .setTrickles(data: .isLoading(last: result)))
                        return .chanshi(action: .listAllTrickles(workspaceID: workspaceID,
                                                                 channelID: channelID,
                                                                 memberID: memberID,
                                                                 until: nextTS))
                    } else {
                        return .chanshi(action: .setTrickles(data: .loaded(data: result)))
                    }
                }
                .catch({ error in
                    return Just(.chanshi(action: .setTrickles(data: .failed(.unexpected(error: error)))))
                })
                .eraseToAnyPublisher()
            
        case .setParticipants(let members):
            state.participants = .loaded(data: members.formDictionary(key: \.memberID))
            
        case .loadParticipants(let channelMembers):
            guard state.trickles.state == .loaded else { break }
            state.participants = .isLoading(last: state.participants.value)
            
            let posts = state.trickles.value?.values.filter { trickle in
                TrickleIntergratable.getType(trickle.blocks) == .helloWorld
            } ?? []
            var uniqueMemberIDs = Set<String>()
            for post in posts {
                uniqueMemberIDs.insert(post.authorMemberInfo.memberID)
            }
            let participants: [MemberData] = channelMembers.filter {
                uniqueMemberIDs.contains($0.memberID)
            }
            return Just(.chanshi(action: .setParticipants(members: participants)))
                .eraseToAnyPublisher()
            
        case .setUserChannelState(let channelState):
            state.userChannelState = channelState
            
        case .checkHasJoined(let memberID):
            guard state.trickles.state == .loaded else { break }
            guard let _ = state.trickles.value?.values.first(where: {
                return TrickleIntergratable.getType($0.blocks) == .helloWorld && $0.authorMemberInfo.memberID == memberID
            }) else {
                return Just(AppAction.chanshi(action: .setUserChannelState(.notJoined)))
                    .eraseToAnyPublisher()
            }
            return Just(.chanshi(action: .setUserChannelState(.joined)))
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
        
            
        case .weekStateCheck:
            func setAsFinishedWeek() {
                state.lastWeekState = .finished
                state.currentWeekState = .finished
            }
            
            func setAsUnderwayWeek() {
                state.lastWeekState = .finished
                state.currentWeekState = .underway
            }
            
            guard state.trickles.state == .loaded else { break }
            
            guard let latestGamble = state.latestGamble,
                  let latestSummary = state.latestSummary else {
                /// 初始周
                setAsUnderwayWeek()
                break
            }
            
            let latestGambleWeek = getWeek(second: latestGamble.createAt)
            let latestSummaryWeek = getWeek(second: latestSummary.createAt)
            
            guard latestSummaryWeek < currentWeek else {
                setAsFinishedWeek()
                break
            }
            setAsUnderwayWeek()
            
            let weekDiff = latestGambleWeek - latestSummaryWeek
            // TODO: publish summary
            
            
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
        
        case .getLatestSummary:
            guard state.trickles.state == .loaded else { break }
            
            if let summaryInfo = TrickleIntergratable.getLatestSummary(trickles: state.allTrickles) {
                if summaryInfo.week == currentWeek {
                    state.currentWeekState = .finished
                    state.lastWeekState = .finished
                } else if summaryInfo.week == currentWeek - 1 {
                    state.currentWeekState = .underway
                    state.lastWeekState = .finished
                } else {
                    // 依次补发
                }
            } else {
                
            }
    }
    
    
    return Empty().eraseToAnyPublisher()
}
