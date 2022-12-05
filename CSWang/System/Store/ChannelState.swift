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
    var currentChannel: GroupData? {
        channels[currentChannelID ?? ""]
    }
    
    
    private func getCSChannel(channels: [GroupData]) -> GroupData? {
        return channels.first { channel in
            channel.name == "Who's shit?"
        }
    }
}

enum ChannelAction {
    case setChannels(items: [GroupData])
    case createChannel(workspaceID: String, memberID: String, invitedMemberIDs: [String])
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
            
//            print(state.currentChannelID)
            
        case let .createChannel(workspaceID, memberID, invitedMemberIDs):
            return environment.trickleWebRepository
                .createChannel(workspaceID: workspaceID,
                               memberID: memberID,
                               invitedMemberIDs: invitedMemberIDs)
                .map { [state] in
                    ChannelAction.setChannels(items: state.allChannels + [$0])
                }
                .catch { _ in
                    Empty()
                }
                .eraseToAnyPublisher()
            
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
