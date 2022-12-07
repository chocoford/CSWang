//
//  ChannelState.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/2.
//

import Foundation
import Combine
import OSLog

enum ChannelError: Error {
    case unjoined
    
}

struct ChannelState {
    var channels: Loadable<[String: GroupData]> = .notRequested
    
    var allChannels: [GroupData] {
        (channels.value ?? [:]).values.sorted {
            $0.createAt ?? 0 < $1.createAt ?? 0
        }
    }
    
    var currentChannelID: String?
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
    
    var channelPosts: Loadable<[TrickleData]> = .notRequested
    
    var chanshi: CSState = .init()
}

enum ChannelAction {
    case noAction
    case setChannels(items: [GroupData])
//    case setCurrentChannel(channelID: String?)
    case createChannel(workspaceID: String, memberID: String, invitedMemberIDs: [String])
    case listPublicChannels(workspaceID: String, memberID: String)
    
    @available(*, deprecated, message: "Will not be used")
    case listPrivateChannels(workspaceID: String, memberID: String)
    
    case createTrickle(workspaceID: String, channelID: String, payload: TrickleWebRepository.API.CreatePostPayload)
    
    case setChannelPosts(data: Loadable<[TrickleData]>)
    case listTrickles(workspaceID: String, channelID: String, memberID: String, until: Int?)
}

func channelReducer(state: inout ChannelState,
                    action: ChannelAction,
                    environment: AppEnvironment) -> AnyPublisher<AppAction, Never> {
//    let logger = Logger(subsystem: "CSWang", category: "channelReducer")
    switch action {
        case .noAction:
            break
        case .setChannels(let items):
            state.channels = .loaded(data: items.formDictionary(key: \.groupID))
            state.chanshi.participants = .notRequested
            
            // get specific channel

            state.currentChannelID = state.channels.value!.values.first {
               $0.name == "Who's shit?"
            }?.groupID
            
        case let .createChannel(workspaceID, memberID, invitedMemberIDs):
            return environment.trickleWebRepository
                .createChannel(workspaceID: workspaceID,
                               memberID: memberID,
                               invitedMemberIDs: invitedMemberIDs)
                .map { [state] in
                        .channel(action: .setChannels(items: state.allChannels + [$0.group]))
                }
                .catch { _ in
                    Empty()
                }
                .eraseToAnyPublisher()

        case let .listPublicChannels(workspaceID, memberID):
            state.channels = .isLoading(last: nil)
            return environment.trickleWebRepository
                .listWorkspacePublicChannels(workspaceID: workspaceID, memberID: memberID)
                .map({ streamable in
                    streamable.items
                })
                .replaceError(with: [])
                .map({
                    return .channel(action: .setChannels(items: $0))
                })
                .eraseToAnyPublisher()
            
        case let .listPrivateChannels(workspaceID, memberID):
            state.channels = .isLoading(last: nil)
            return environment.trickleWebRepository
                .listWorkspacePrivateChannels(workspaceID: workspaceID, memberID: memberID)
                .map({ streamable in
                    streamable.items
                })
                .replaceError(with: [])
                .map({
                    return .channel(action: .setChannels(items: $0))
                })
                .eraseToAnyPublisher()
            
        case let .createTrickle(workspaceID, channelID, payload):
            return environment.trickleWebRepository
                .createPost(workspaceID: workspaceID,
                            channelID: channelID,
                            payload: payload)
                .map { _ in
                    return .nap
                }
                .catch { _ in
                    Empty()
                }
                .eraseToAnyPublisher()
            
        case .setChannelPosts(let data):
            state.channelPosts = data
        
        case .listTrickles(let workspaceID, let channelID, let memberID, let until):
            return environment.trickleWebRepository
                .listPosts(workspaceID: workspaceID,
                           query: .init(workspaceID: workspaceID, receiverID: channelID, memberID: memberID, until: until, limit: 40))
                .retry(3)
                .map { [state] in
                    _ = AppAction.channel(action: .setChannelPosts(data: .isLoading(last: (state.channelPosts.value ?? []) + $0.items)))
                    if let nextTS = $0.nextTs {
                        return .channel(action: .listTrickles(workspaceID: workspaceID,
                                                              channelID: channelID,
                                                              memberID: memberID,
                                                              until: nextTS))
                    } else {
                        return .nap
                    }
                }
                .catch({ error in
                    return Just(.channel(action: .setChannelPosts(data: .failed(.unexpected(error: error)))))
                })
                .eraseToAnyPublisher()
            
    }
    
    return Empty().eraseToAnyPublisher()
}


// MARK: - GroupData
struct GroupData: Codable {
    let name, groupID, ownerID: String
    let isGeneral, isWorkspacePublic: Bool?
    let createAt, updateAt: Int?

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


extension GroupData: Equatable {}


// MARK: - TrickleData
struct TrickleData: Codable {
    let trickleID: String
    let authorMemberInfo: MemberData
//    let receiverInfo: ReceiverInfo
    let createAt, updateAt: Int
    let editAt: Int?
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
