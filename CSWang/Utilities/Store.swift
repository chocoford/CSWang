//
//  Store.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/28.
//

import SwiftUI
import Combine

/// `Environment` might be a plain struct that holds all needed dependencies like service and manager classes.
typealias Reducer<State, Action, Environment> = (inout State, Action, Environment) -> AnyPublisher<Action, Never>?

@MainActor
final class Store<State, Action, Environment>: ObservableObject {
    @Published private(set) var state: State
    
    private let environment: Environment
    private let reducer: Reducer<State, Action, Environment>
    
    init(state: State, reducer: @escaping Reducer<State, Action, Environment>, environment: Environment) {
        self.state = state
        self.reducer = reducer
        self.environment = environment
    }
    
    func send(_ action: Action) async {
        /// side effect
        /// 返回的是Publihser
        guard let effect = reducer(&state, action, environment) else {
            return
        }
        
        for await action in effect.values {
            await send(action)
        }
    }
}

