//
//  AppDelegateIOS.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/12.
//
#if os(iOS)
import Foundation
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationWillTerminate(_ application: UIApplication) {
        TrickleWebSocket.shared.close()
    }
}

#endif
