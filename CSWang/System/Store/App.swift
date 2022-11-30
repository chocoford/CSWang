//
//  AppState.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/28.
//

import Foundation
import Combine

struct AppState {
    #if DEBUG
    static let preview: AppState = .init()
    #endif
    
    var user: UserState = .init()
    var workspace: WorkspaceState = .init()
}

enum AppAction {
    case user(action: UserAction)
    case workspace(action: WorkspaceAction)
}

typealias AppStore = Store<AppState, AppAction, AppEnvironment>


func appReducer(state: inout AppState, action: AppAction, environment: AppEnvironment) -> AnyPublisher<AppAction, Never> {
    switch action {
        case .user(let action):
            return userReducer(state: &state.user, action: action, environment: environment)
                .map(AppAction.user)
                .eraseToAnyPublisher()
        case .workspace(let action):
            return workspaceReducer(state: &state.workspace, action: action, environment: environment)
                .map(AppAction.workspace)
                .eraseToAnyPublisher()
            break
    }
    return Empty().eraseToAnyPublisher()
}
