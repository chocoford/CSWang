//
//  AppEnviornment.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/28.
//

import Foundation

struct AppEnvironment {
    let trickleWebRepository: TrickleWebRepository
    
    init() {
        let session = Self.configuredURLSession()
        trickleWebRepository = .init(session: session, baseURL: "https://devapp.trickle.so/api")
//        TrickleWebSocket.shared.socketSession = session
    }
    
    private static func configuredURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 120
        configuration.waitsForConnectivity = true
        configuration.httpMaximumConnectionsPerHost = 5
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = .shared
        return URLSession(configuration: configuration)
    }
    
}
