//
//  AppDelegate.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/30.
//

import Foundation

#if os(macOS)
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        TrickleWebSocket.shared.close()
    }
}

#endif
