//
//  AuthMiddleware.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/30.
//

import Foundation

final class AuthMiddleware {
    static let shared = AuthMiddleware()
    static let service = "devapp.trickle.so"
    static let account = "com.chocoford.CSWang"
    
    var token: String? = nil
    
    init() {
        getTokenFromKeychain()
    }
    
    private func getTokenFromKeychain() {
        guard let userInfo: UserInfo = KeychainHelper.standard.read(service: Self.service, account: Self.account) else {
            return
        }
        self.token = userInfo.token
    }
    
//    private func saveTokenToKeychain() {
//        guard let userInfo: UserInfo = KeychainHelper.standard.save(, service: Self.service, account: Self.account) else {
//            return
//        }
//        self.token = userInfo.token
//    }
//    
    public func updateToken(token: String) {
        self.token = token
    }
}
