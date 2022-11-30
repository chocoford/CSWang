//
//  CSWangApp.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/28.
//

import SwiftUI

@main
@MainActor
struct CSWangApp: App {
    let store = AppStore(state: AppState(),
                         reducer: appReducer,
                         environment: .init())
//    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
