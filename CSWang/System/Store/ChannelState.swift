//
//  ChannelState.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/2.
//

import Foundation
import Combine

struct ChannelState {
    var channels: [String: GroupData] = [:]
    var allChannels: [GroupData] {
        channels.values.sorted {
            $0.createAt < $1.createAt
        }
    }
    var currentChannelID: String?
    var channelInfo: GroupData? = nil
}

enum ChannelAction {
    case setChannels(items: [GroupData])
    case listPrivateChannels(workspaceID: String, memberID: String)
}

func channelReducer(state: inout ChannelState,
                    action: ChannelAction,
                    environment: AppEnvironment) -> AnyPublisher<ChannelAction, Never> {
    switch action {
        case .setChannels(let items):
            state.channels = items.formDictionary(key: \.groupID)
            
            // get specific channel
            state.currentChannelID = state.channels.values.first {
                $0.name == "Who's shit?"
            }?.groupID
            
        case let .listPrivateChannels(workspaceID, memberID):
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
    }
    
    return Empty().eraseToAnyPublisher()
}


// MARK: - GroupData
struct GroupData: Codable {
    let name, groupID, ownerID: String
    let isGeneral, isWorkspacePublic: Bool
    let createAt, updateAt: Int

    enum CodingKeys: String, CodingKey {
        case name
        case groupID = "groupId"
        case ownerID = "ownerId"
        case isGeneral, isWorkspacePublic, createAt, updateAt
    }
}
