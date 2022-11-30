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
    var userInfo: UserInfo? = nil
    
    //MARK: Getters
    var hasLogin: Bool {
        self.userInfo != nil
    }
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

        case let .getUserInfo(token):
            guard let tokenInfo = decodeToken(token: token) else {
                logger.error("can not decode token: \(token)")
                break
            }
            AuthMiddleware.shared.updateToken(token: token)
            
            return environment.trickleWebRepository
                .getUserData(userID: tokenInfo.sub)
                .replaceError(with: nil)
                .map {
                    return UserAction.setUserInfo(userInfo: $0)
                }
                .eraseToAnyPublisher()
    }
    
    return Empty().eraseToAnyPublisher()
}

