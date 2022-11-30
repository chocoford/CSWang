//
//  WorkspaceState.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/30.
//

import Foundation
import Combine


struct WorkspaceState {
    var workspaces: [String: WorkspaceData] = [:]
}


enum WorkspaceAction {
    case listWorkspaces
}


func workspaceReducer(state: inout WorkspaceState,
                     action: WorkspaceAction,
                     environment: AppEnvironment) -> AnyPublisher<WorkspaceAction, Never> {
    
    return Empty().eraseToAnyPublisher()
}


struct WorkspaceData {
    
}
