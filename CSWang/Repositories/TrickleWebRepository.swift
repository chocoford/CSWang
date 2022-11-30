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
}

// MARK: - Endpoints

extension TrickleWebRepository {
    enum API {
//        case login
        case getUserData(userID: String)
        case listWorkspaces(userID: String)
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
                //            case .listPosts:
                //                return "/workspaces/30788161542029315/trickles?limit=5&memberId=30799568975167493&workspaceId=30788161542029315&version=1669566798516&apiVersion=2"
        }
    }
    var method: String {
        switch self {
            case .getUserData, .listWorkspaces:
                return "GET"
        }
    }
    var headers: [String: String]? {
        return ["Accept": "application/json", "Authorization": "Bearer \(AuthMiddleware.shared.token ?? "")"]
    }
    func body() throws -> Data? {
        return nil
    }
}
