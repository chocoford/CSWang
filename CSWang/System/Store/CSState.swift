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
    
    
}

enum CSAction {
    case setParticipants(members: [MemberData])
    case loadParticipants(workspaceID: String, channelID: String, memberID: String, channelMembers: [MemberData])
    
    case setUserChannelState(_ state: CSState.UserChannelState)
    case joinCSChannel(workspaceID: String, channelID: String, memberID: String)
    case checkHasJoined(workspaceID: String, channelID: String, memberID: String)
    
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
    }
    
    
    return Empty().eraseToAnyPublisher()
}
