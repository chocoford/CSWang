//
//  ChannelState.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/2.
//

import Foundation
import Combine

struct ChannelState {
    var channels: Loadable<[String: GroupData]> = .notRequested
    
    var allChannels: [GroupData] {
        (channels.value ?? [:]).values.sorted {
            $0.createAt ?? 0 < $1.createAt ?? 0
        }
    }
    
    var currentChannelID: String?
    var currentChannel: Loadable<GroupData?> {
        switch channels {
            case .notRequested:
                return .notRequested
            case .isLoading(let last):
                return .isLoading(last: last?[currentChannelID ?? ""])
            case .loaded(let data):
                let current = data[currentChannelID ?? ""]
                return .loaded(data: current)
                
            case .failed(let error):
                return .failed(error)
        }
    }
}

enum ChannelAction {
    case noAction
    case setChannels(items: [GroupData])
    case createChannel(workspaceID: String, memberID: String, invitedMemberIDs: [String])
    case listPublicChannels(workspaceID: String, memberID: String)
    
    @available(*, deprecated, message: "Will not be used")
    case listPrivateChannels(workspaceID: String, memberID: String)
    
    case createTrickle(workspaceID: String, channelID: String, payload: TrickleWebRepository.API.CreatePostPayload)

}

func channelReducer(state: inout ChannelState,
                    action: ChannelAction,
                    environment: AppEnvironment) -> AnyPublisher<ChannelAction, Never> {
    switch action {
        case .noAction:
            break
        case .setChannels(let items):
            state.channels = .loaded(data: items.formDictionary(key: \.groupID))
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
                    ChannelAction.setChannels(items: state.allChannels + [$0.group])
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
                    return ChannelAction.setChannels(items: $0)
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
                    return ChannelAction.setChannels(items: $0)
                })
                .eraseToAnyPublisher()
            
        case let .createTrickle(workspaceID, channelID, payload):
            return environment.trickleWebRepository
                .createPost(workspaceID: workspaceID,
                            channelID: channelID,
                            payload: payload)
                .map { _ in
                    return ChannelAction.noAction
                }
                .catch { _ in
                    Empty()
                }
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
    let title: String
    let blocks: [Block]
//    let tagInfo, mentionedMemberInfo: [JSONAny]
    let isPublic, allowGuestMemberComment, allowGuestMemberReact, allowWorkspaceMemberComment: Bool
    let allowWorkspaceMemberReact: Bool
    let likeCounts, commentCounts: Int
    let hasLiked: Bool
//    let latestLikeMemberInfo, commentInfo, referTrickleInfo, reactionInfo: [JSONAny]
//    let viewedMemberInfo: ViewedMemberInfo
//    let threadID: JSONNull?

    enum CodingKeys: String, CodingKey {
        case trickleID = "trickleId"
        case authorMemberInfo, createAt, updateAt, title, blocks, isPublic, allowGuestMemberComment, allowGuestMemberReact, allowWorkspaceMemberComment, allowWorkspaceMemberReact, likeCounts, commentCounts, hasLiked
//        case receiverInfo, tagInfo, latestLikeMemberInfo, viewedMemberInfo, commentInfo, referTrickleInfo, reactionInfo,
//        case threadID = "threadId"
    }
}
