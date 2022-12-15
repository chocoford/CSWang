//
//  TrickleWebReposities.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/28.
//

import Foundation
import Combine
import OSLog

protocol TrickleWebRepositable: WebRepository {
    func getUserData(userID: String) -> AnyPublisher<UserInfo?, Error>
    
    func listUserWorkspaces(userID: String) -> AnyPublisher<AnyStreamable<WorkspaceData>, Error>
    
    func listWorkspacePublicChannels(workspaceID: String, memberID: String) -> AnyPublisher<AnyStreamable<GroupData>, Error>
    func listWorkspacePrivateChannels(workspaceID: String, memberID: String) -> AnyPublisher<AnyStreamable<GroupData>, Error>
    
    func listChannelMembers(workspaceID: String, channelID: String?) -> AnyPublisher<AnyStreamable<MemberData>, Error>
    
    func createChannel(workspaceID: String,
                       memberID: String,
                       invitedMemberIDs: [String]) -> AnyPublisher<GroupDataWrapper, Error>
    
    func createPost(workspaceID: String,
                    channelID: String,
                    payload: TrickleWebRepository.API.CreatePostPayload) -> AnyPublisher<TrickleData, Error>
    
    func listPosts(workspaceID: String, query: TrickleWebRepository.API.ListPostsQuery) -> AnyPublisher<AnyStreamable<TrickleData>, Error>
}

struct TrickleWebRepository: TrickleWebRepositable {
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
    
    func listWorkspacePublicChannels(workspaceID: String, memberID: String) -> AnyPublisher<AnyStreamable<GroupData>, Error> {
        call(endpoint: API.listPublicChannels(workspaceID: workspaceID, memberID: memberID))
    }
    
    func listWorkspacePrivateChannels(workspaceID: String, memberID: String) -> AnyPublisher<AnyStreamable<GroupData>, Error> {
        call(endpoint: API.listPrivateChannels(workspaceID: workspaceID, memberID: memberID))
    }
    
    func listChannelMembers(workspaceID: String, channelID: String?) -> AnyPublisher<AnyStreamable<MemberData>, Error> {
        call(endpoint: API.listChannelMembers(workspaceID: workspaceID, channelID: channelID))
    }
    
    func createChannel(workspaceID: String,
                       memberID: String,
                       invitedMemberIDs: [String]) -> AnyPublisher<GroupDataWrapper, Error> {
        call(endpoint: API.createChannel(workspaceID: workspaceID,
                                         memberID: memberID,
                                         invitedMemberIDs: invitedMemberIDs))
    }
    
    func createPost(workspaceID: String,
                     channelID: String,
                     payload: TrickleWebRepository.API.CreatePostPayload) -> AnyPublisher<TrickleData, Error> {
        call(endpoint: API.createPost(workspaceID: workspaceID, channelID: channelID, payload: payload))
    }
    
    func listPosts(workspaceID: String,
                     query: TrickleWebRepository.API.ListPostsQuery) -> AnyPublisher<AnyStreamable<TrickleData>, Error> {
        call(endpoint: API.listPosts(workspaceID: workspaceID, payload: query))
    }
}

// MARK: - Endpoints

extension TrickleWebRepository {
    
    enum API {
        case getUserData(userID: String)
        case listWorkspaces(userID: String)
        case listPublicChannels(workspaceID: String, memberID: String)
        case listPrivateChannels(workspaceID: String, memberID: String)
        case listChannelMembers(workspaceID: String, channelID: String?)
        case createChannel(workspaceID: String, memberID: String, invitedMemberIDs: [String])
        
        struct CreatePostPayload: Codable {
            let authorMemberID: String
            let blocks: [Block]
            let mentionedMemberIDs: [String]
            
            enum CodingKeys: String, CodingKey {
                case authorMemberID = "authorMemberId"
                case blocks
                case mentionedMemberIDs = "mentionedMemberIds"
            }
            
            init(authorMemberID: String, blocks: [Block], mentionedMemberIDs: [String] = []) {
                self.authorMemberID = authorMemberID
                self.blocks = blocks
                self.mentionedMemberIDs = mentionedMemberIDs
            }
        }
        case createPost(workspaceID: String, channelID: String, payload: CreatePostPayload)
        
        struct ListPostsQuery: Codable {
            let workspaceID: String
            let receiverID: String
            let memberID: String
            let authorID: String?
            let text: String?
            let until: Int?
            let limit: Int?
            let order: Int?
            
            enum CodingKeys: String, CodingKey {
                case workspaceID = "workspaceId"
                case receiverID = "receiverIds"
                case memberID = "memberId"
                case authorID = "authorId"
                case text, until, limit, order
            }
            
            init(workspaceID: String, receiverID: String, memberID: String, authorID: String? = nil, text: String? = nil, until: Int? = nil, limit: Int? = 10, order: Int? = nil) {
                self.workspaceID = workspaceID
                self.receiverID = receiverID
                self.memberID = memberID
                self.authorID = authorID
                self.text = text
                self.until = until
                self.limit = limit
                self.order = order
            }
        }
        case listPosts(workspaceID: String, payload: ListPostsQuery)

    }
}

extension TrickleWebRepository.API: APICall {
    var path: String {
        switch self {
            case .getUserData(let userID):
                return "/auth/user/\(userID)"
                
            case .listWorkspaces(let userID):
                return "/f2b/v1/workspaces?userId=\(userID)"

            case let .listPublicChannels(workspaceID, memberID):
                return "/f2b/v1/workspaces/\(workspaceID)/publicGroups?memberId=\(memberID)"
                
            case let .listPrivateChannels(workspaceID, memberID):
                return "/f2b/v1/workspaces/\(workspaceID)/privateGroups?memberId=\(memberID)"
                
            case let .listChannelMembers(workspaceID, channelID):
                if let channelID = channelID {
                    return "/f2b/v1/workspaces/\(workspaceID)/groups/\(channelID)/members?limit=1024&"
                }
                return "/f2b/v1/workspaces/\(workspaceID)/members?limit=1024"

            case let .createChannel(workspaceID, _, _):
                return "/f2b/v1/workspaces/\(workspaceID)/groups"

            // MARK: - Post CRUD API
            case .createPost(let workspaceID, let channelID, _):
                return "/f2b/v1/workspaces/\(workspaceID)/groups/\(channelID)/trickles"
                
            case let .listPosts(workspaceID, _):
                return "/f2b/v1/workspaces/\(workspaceID)/trickles"
                
        }
    }
    
    var gloabalQueryItems: Codable? {
        struct TrickleWebAPIQuery: Codable {
            var version: Int = Int(Date().timeIntervalSince1970 * 1000)
            var apiVersion: Int = 2
        }
        return TrickleWebAPIQuery()
    }

    var queryItems: Codable? {
        switch self {
            case .listPosts(_, let payload):
                return payload
            default:
                return nil
        }
    }
    
    var method: APIMethod {
        switch self {
            case .createChannel, .createPost:
                return .post
                
            default:
                return .get
        }
    }
    var headers: [String: String]? {
        var defaults = [
            "Accept": "*/*",
            "Authorization": "Bearer \(AuthMiddleware.shared.token ?? "")",
            "trickle-trace-id": UUID().uuidString.replacingOccurrences(of: "-", with: ""),
            "trickle-api-version": "2",
        ]
        
        switch self {
            case .createChannel, .createPost:
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
                                      isWorkspacePublic: true,
                                      ownerId: memberID)
                return try makeBody(payload: payload)
                
            case .createPost(_, _, let payload):
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
