//
//  AuthMiddleware.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/30.
//

import Foundation
import OSLog

final class AuthMiddleware {
    static let shared = AuthMiddleware()
    static let service = "devapp.trickle.so"
    static let account = "com.chocoford.CSWang"
    
    let logger = Logger(subsystem: "CSWang", category: "AuthMiddleware")
    
    var token: String? = nil
    
    init() {}
    
    public func getTokenFromKeychain() -> UserInfo? {
        guard let userInfo: UserInfo = KeychainHelper.standard.read(service: Self.service, account: Self.account) else {
            logger.info("no auth info.")
            return nil
        }
        
        self.token = userInfo.token
        
        return userInfo
    }
    
    public func saveTokenToKeychain(userInfo: UserInfo) {
        guard userInfo.token != nil else {
            return
        }
        KeychainHelper.standard.save(userInfo, service: Self.service, account: Self.account)
        updateToken(token: userInfo.token!)
    }
    
    public func updateToken(token: String) {
        self.token = token
    }
    
    public func removeToken() {
        KeychainHelper.standard.delete(service: Self.service, account: Self.account)
        self.token = nil
    }
}
