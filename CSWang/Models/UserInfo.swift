//
//  UserInfo.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/29.
//

import Foundation

struct TokenInfo: Codable {
    let sub: String
    let iat: Int
    let exp: Int
    let scope: String
    
    let token: String
}

struct UserInfo: Codable, Equatable {
    struct UserData: Codable, Equatable {
        let id: String
        let name: String?
        let email: String?
        let avatarUrl: URL?
    }
    
    let user: UserData
    
    var token: String?
    
    
    struct KeychainRepresentation: Codable {
        let id: UUID
        let token: String
    }
//    func getKeychainRepresentation() throws -> KeychainRepresentation {
//        guard self.id != nil && self.token != nil else { throw AuthError.userIdMissing }
//        return KeychainRepresentation(id: self.id!, token: self.token!)
//    }
}
