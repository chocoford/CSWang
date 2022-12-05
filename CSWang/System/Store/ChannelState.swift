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
            $0.createAt < $1.createAt
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
    case setChannels(items: [GroupData])
    case createChannel(workspaceID: String, memberID: String, invitedMemberIDs: [String])
    case listPrivateChannels(workspaceID: String, memberID: String)
}

func channelReducer(state: inout ChannelState,
                    action: ChannelAction,
                    environment: AppEnvironment) -> AnyPublisher<ChannelAction, Never> {
    switch action {
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
                    ChannelAction.setChannels(items: state.allChannels + [$0])
                }
                .catch { _ in
                    Empty()
                }
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


extension GroupData: Equatable {
     
}
