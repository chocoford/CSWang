//
//  WorkspaceState.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/30.
//

import Foundation
import Combine


struct WorkspaceState {
    var workspaces: Loadable<[String: WorkspaceData]> = .notRequested
    var allWorkspaces: [WorkspaceData] {
        (workspaces.value ?? [:]).values.sorted {
            $0.createAt < $1.createAt
        }
    }
    var currentWorkspaceID: String?
    {
        willSet(val) {
            members = nil
            channel = .init()
        }
    }
    
    
    var currentWorkspace: WorkspaceData? {
        currentWorkspaceID != nil ? workspaces.value?[currentWorkspaceID!] : nil
    }
    
    var channel: ChannelState = .init()
    
    var members: [String: MemberData]? = nil
    var allMembers: [MemberData]? {
        guard let members = members else {
            return nil
        }
        return members.values.sorted {
            $0.name.hashValue < $1.name.hashValue
        }
    }
}



enum WorkspaceAction {
    case setWorkspaces(items: [WorkspaceData])
    case setWorkspaceMembers(members: [MemberData])
    case setCurrentWorkspace(workspaceID: String?)
    case listWorkspaces(userID: String)
    case listWorkspaceMembers(workspaceID: String)
}


func workspaceReducer(state: inout WorkspaceState,
                     action: WorkspaceAction,
                     environment: AppEnvironment) -> AnyPublisher<WorkspaceAction, Never> {
    switch action {
        case .setWorkspaces(items: let items):
            state.workspaces = .loaded(data: items.formDictionary(key: \.workspaceID))
            state.channel.channels = .notRequested
            
        case .setWorkspaceMembers(let members):
            state.members = members.formDictionary(key: \.memberID)
            
        case let .setCurrentWorkspace(workspaceID):
            state.currentWorkspaceID = workspaceID
        
        case let .listWorkspaces(userID):
            state.workspaces = .isLoading(last: nil)
            return environment.trickleWebRepository
                .listUserWorkspaces(userID: userID)
                .map({ streamable in
                    streamable.items
                })
                .replaceError(with: [])
                .map {
                    return WorkspaceAction.setWorkspaces(items: $0)
                }
                .eraseToAnyPublisher()
            
        case .listWorkspaceMembers(let workspaceID):
            return environment.trickleWebRepository
                .listChannelMembers(workspaceID: workspaceID, channelID: nil)
                .map({ streamable in
                    streamable.items
                })
                .replaceError(with: [])
                .map {
                    return WorkspaceAction.setWorkspaceMembers(members: $0)
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
    let createAt, updateAt: Int
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


// MARK: - MemberData
struct MemberData: Codable, Equatable {
    let name, role, status, memberID, avatarURL: String
    let email: String?
    let createAt, updateAt: Int?

    enum CodingKeys: String, CodingKey {
        case name, role, email, status
        case memberID = "memberId"
        case avatarURL = "avatarUrl"
        case createAt, updateAt
    }
}


extension MemberData: Hashable {
    
}
