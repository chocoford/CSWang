//
//  TrickleWebReposities.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/28.
//

import Foundation
import Combine
import OSLog

struct TrickleWebRepository: WebRepository {    
    var logger: Logger = .init(subsystem: "CSWang", category: "TrickleWebRepository")
    var session: URLSession
    var baseURL: String
    var bgQueue: DispatchQueue = DispatchQueue(label: "bg_trickle_queue")
    
    init(session: URLSession, baseURL: String) {
        self.session = session
        self.baseURL = baseURL
    }
    
    func getUserData(userID: String) -> AnyPublisher<UserInfo?, Error> {
        call(endpoint: API.getUserData(userID: userID))
    }
    
    func listUserWorkspaces(userID: String) -> AnyPublisher<AnyStreamable<WorkspaceData>, Error> {
        call(endpoint: API.listWorkspaces(userID: userID))
    }
    
    func listWorkspacePrivateChannels(workspaceID: String, memberID: String) -> AnyPublisher<AnyStreamable<GroupData>, Error> {
        call(endpoint: API.listPrivateChannels(workspaceID: workspaceID, memberID: memberID))
    }
    
    func listChannelMembers(workspaceID: String, channelID: String?) -> AnyPublisher<AnyStreamable<MemberData>, Error> {
        call(endpoint: API.listChannelMembers(workspaceID: workspaceID, channelID: channelID))
    }
    
    func createChannel(workspaceID: String,
                       memberID: String,
                       invitedMemberIDs: [String]) -> AnyPublisher<GroupData, Error> {
        call(endpoint: API.createChannel(workspaceID: workspaceID,
                                         memberID: memberID,
                                         invitedMemberIDs: invitedMemberIDs))
    }
}

// MARK: - Endpoints

extension TrickleWebRepository {
    enum API {
        case getUserData(userID: String)
        case listWorkspaces(userID: String)
        case listPrivateChannels(workspaceID: String, memberID: String)
        case listChannelMembers(workspaceID: String, channelID: String?)
        case createChannel(workspaceID: String, memberID: String, invitedMemberIDs: [String])
    }
}

extension TrickleWebRepository.API: APICall {
    
    var path: String {
        switch self {
            case .getUserData(let userID):
                return "/auth/user/\(userID)"
                
            case .listWorkspaces(let userID):
                return "/f2b/v1/workspaces?userId=\(userID)"
                
            case let .listPrivateChannels(workspaceID, memberID):
                return "/f2b/v1/workspaces/\(workspaceID)/privateGroups?memberId=\(memberID)&version=\(Int(Date().timeIntervalSince1970))"
                
            case let .listChannelMembers(workspaceID, channelID):
                if let channelID = channelID {
                    return "/f2b/v1/workspaces/\(workspaceID)/groups/\(channelID)/members?limit=1024&version=\(Int(Date().timeIntervalSince1970))"
                }
                return "/f2b/v1/workspaces/\(workspaceID)/members?limit=1024&version=\(Int(Date().timeIntervalSince1970))"

            case let .createChannel(workspaceID, _, _):
                return "/f2b/v1/workspaces/\(workspaceID)/groups"

        }
    }
    var method: String {
        switch self {
            case .createChannel:
                return "POST"
                
            default:
                return "GET"
        }
    }
    var headers: [String: String]? {
        
        var defaults = [
            "Accept": "application/json",
            "Authorization": "Bearer \(AuthMiddleware.shared.token ?? "")",
            "trickle-trace-id": UUID().uuidString.replacingOccurrences(of: "-", with: ""),
            "trickle-api-version": "2",
        ]
        
        switch self {
            case .createChannel:
                defaults["Content-Type"] = "application/json"
            default:
                break
        }
        return defaults
    }
    func body() throws -> Data? {
        switch self {
            case let .createChannel(_, memberID, invitedMemberIDs):
                struct Payload: Codable {
                    let name: String
                    let memberIds: [String]
                    let isWorkspacePublic: Bool
                    let ownerId: String
                }
                let payload = Payload(name: "Who's shit?",
                                      memberIds: invitedMemberIDs,
                                      isWorkspacePublic: false,
                                      ownerId: memberID)
                return try makeBody(payload: payload)
            default:
                return nil
        }
        
    }
}


struct AnyStreamable<T: Codable>: Codable {
    let items: [T]
    let nextTs: Int?
}
