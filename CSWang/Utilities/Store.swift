//
//  Store.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/28.
//

import SwiftUI
import Combine

struct Reducer<State, Action, Environment> {
    let reduce: (inout State, Action, Environment) -> AnyPublisher<Action, Never>
    
    func callAsFunction(
        _ state: inout State,
        _ action: Action,
        _ environment: Environment
    ) -> AnyPublisher<Action, Never> {
        reduce(&state, action, environment)
    }
}

@MainActor
final class Store<State, Action, Environment>: ObservableObject {
    @Published private(set) var state: State
    
    private let environment: Environment
    private let reducer: (inout State, Action) -> AnyPublisher<Action, Never>
    
    init(state: State, reducer: Reducer<State, Action, Environment>, environment: Environment) {
        self.state = state
        self.reducer = { state, action in
            reducer(&state, action, environment)
        }
        self.environment = environment
    }
    
    func send(_ action: Action) async {
        let effect = reducer(&state, action)
        
        for await action in effect.values {
            await send(action)
        }
    }
}

extension Store {
    func binding<Value>(
        for keyPath: KeyPath<State, Value>,
        toAction: @escaping (Value) -> Action
    ) -> Binding<Value> {
        Binding<Value>(
            get: { self.state[keyPath: keyPath] },
            set: { val in
                Task {
                    await self.send(toAction(val))
                }
            }
        )
    }
}

