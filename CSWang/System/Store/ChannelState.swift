//
//  ChannelState.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/2.
//

import Foundation
import Combine
import OSLog

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
        
    var chanshi: CSState = .init()
}

enum ChannelAction {
    case addChannels(items: [GroupData])
    case setChannels(items: [GroupData])
    case createChannel(workspaceID: String, memberID: String, invitedMemberIDs: [String])
    case listPublicChannels(workspaceID: String, memberID: String)
    
    @available(*, deprecated, message: "Will not be used")
    case listPrivateChannels(workspaceID: String, memberID: String)
}

func channelReducer(state: inout ChannelState,
                    action: ChannelAction,
                    environment: AppEnvironment) -> AnyPublisher<AppAction, Never> {
//    let logger = Logger(subsystem: "CSWang", category: "channelReducer")
    switch action {
        case .addChannels(let items):
            return Just(.channel(action: .setChannels(items: state.allChannels + items)))
                .eraseToAnyPublisher()
            
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
                .map {
                    .channel(action: .addChannels(items: [$0.group]))
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


