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
    
    func createChannel(workspaceID: String, memberID: String) -> AnyPublisher<GroupData, Error> {
        call(endpoint: API.createChannel(workspaceID: workspaceID, memberID: memberID))
    }
}

// MARK: - Endpoints

extension TrickleWebRepository {
    enum API {
//        case login
        case getUserData(userID: String)
        case listWorkspaces(userID: String)
        case listPrivateChannels(workspaceID: String, memberID: String)
        case listChannelMembers(workspaceID: String, channelID: String?)
        case createChannel(workspaceID: String, memberID: String)
//        case listPosts(String)
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
                return "/f2b/v1/workspaces/\(workspaceID)/privateGroups?memberID=\(memberID)&version=\(Date().timeIntervalSince1970)"
                //            case .listPosts:
                //                return "/workspaces/30788161542029315/trickles?limit=5&memberId=30799568975167493&workspaceId=30788161542029315&version=1669566798516&apiVersion=2"
            
                
            case let .listChannelMembers(workspaceID, channelID):
                if let channelID = channelID {
                    return "/f2b/v1/workspaces/\(workspaceID)/groups/\(channelID)/members?limit=1024&version=\(Date().timeIntervalSince1970)"
                }
                return "/f2b/v1/workspaces/\(workspaceID)/members?limit=1024&version=\(Date().timeIntervalSince1970)"

            case let .createChannel(workspaceID, _):
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
        return ["Accept": "application/json", "Authorization": "Bearer \(AuthMiddleware.shared.token ?? "")"]
    }
    func body() throws -> Data? {
        switch self {
            case let .createChannel(_, memberID):
                struct Payload: Codable {
                    let name: String
                    let memberIds: [String]
                    let isWorkspacePublic: Bool
                    let ownerId: String
                }
                let payload = Payload(name: "CS-Wang",
                                      memberIds: [],
                                      isWorkspacePublic: false,
                                      ownerId: memberID)
                return try TrickleWebRepository.makeBody(payload: payload)
            default:
                return nil
        }
        
    }
}


struct AnyStreamable<T: Codable>: Codable {
    let items: [T]
    let nextTs: Int?
}
