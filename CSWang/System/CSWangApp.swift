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
    @Environment(\.scenePhase) var scenePhase
    
    let store = AppStore(state: AppState(),
                         reducer: appReducer,
                         environment: .init())
    
    let persistenceController = PersistenceController.shared
    
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onChange(of: scenePhase) { _ in
                    persistenceController.save()
                }
        }
    }
}
