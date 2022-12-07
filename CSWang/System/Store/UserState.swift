//
//  UserState.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/30.
//

import Foundation
import Combine
import OSLog

struct UserState {
    var tokenInfo: TokenInfo? = nil
    var userInfo: UserInfo? = nil {
        willSet(val) {
            hasLogin.send(val != nil)
        }
    }
    
    //MARK: Getters
    let hasLogin: PassthroughSubject<Bool, Never> = .init()
}


enum UserAction {
    case setUserInfo(userInfo: UserInfo?)
    case getUserInfo(token: String)
}

 
func userReducer(state: inout UserState,
                 action: UserAction,
                 environment: AppEnvironment) -> AnyPublisher<UserAction, Never> {
    let logger = Logger(subsystem: "CSWang", category: "userReducer")
    switch action {
        case let .setUserInfo(userInfo):
            state.userInfo = userInfo
            if let userInfo = userInfo {
                DispatchQueue.global().async {
                    AuthMiddleware.shared.saveTokenToKeychain(userInfo: userInfo)
                }
            }

        case let .getUserInfo(token):
            guard let tokenInfo = decodeToken(token: token) else {
                logger.error("can not decode token: \(token)")
                break
            }
            
            return environment.trickleWebRepository
                .getUserData(userID: tokenInfo.sub)
                .replaceError(with: nil)
                .map {
                    guard $0 != nil else { return UserAction.setUserInfo(userInfo: nil) }
                    let userInfo = UserInfo(user: $0!.user, token: token)
                    return UserAction.setUserInfo(userInfo: userInfo)
                }
                .eraseToAnyPublisher()
    }
    
    return Empty().eraseToAnyPublisher()
}

