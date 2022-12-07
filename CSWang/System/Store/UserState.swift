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
    var userInfo: Loadable<UserInfo> = .notRequested
}


enum UserAction {
    case loadUserInfo
    case setUserInfo(userInfo: Loadable<UserInfo>)
}

 
func userReducer(state: inout UserState,
                 action: UserAction,
                 environment: AppEnvironment) -> AnyPublisher<AppAction, Never> {
    let logger = Logger(subsystem: "CSWang", category: "userReducer")
    switch action {
        case let .setUserInfo(userInfo):
            state.userInfo = userInfo
            if let userInfo = userInfo.value {
                DispatchQueue.global().async {
                    AuthMiddleware.shared.saveTokenToKeychain(userInfo: userInfo)
                }
                return Just(.workspace(action: .listWorkspaces(userID: userInfo.user.id))).eraseToAnyPublisher()
            }
            

        case .loadUserInfo:
            guard let token = AuthMiddleware.shared.token else {
                break
            }
            guard let tokenInfo = decodeToken(token: token) else {
                logger.error("can not decode token: \(token)")
                break
            }
            
            return environment.trickleWebRepository
                .getUserData(userID: tokenInfo.sub)
                .replaceError(with: nil)
                .map {
                    guard $0 != nil else { return .user(action: .setUserInfo(userInfo: .failed(.notFound))) }
                    let userInfo = UserInfo(user: $0!.user, token: token)
                    return .user(action: .setUserInfo(userInfo: .loaded(data: userInfo)))
                }
                .eraseToAnyPublisher()
    }
    
    return Empty().eraseToAnyPublisher()
}

