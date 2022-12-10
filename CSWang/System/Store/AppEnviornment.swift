//
//  AppEnviornment.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/28.
//

import Foundation

struct AppEnvironment {
    let trickleWebRepository: TrickleWebRepository
//    let trickleWebSocket: WebSocketStream
    //    var socket = WebSocketStream(url: <#T##URL#>)
    
    init() {
        let session = Self.configuredURLSession()
        trickleWebRepository = .init(session: session, baseURL: "https://devapp.trickle.so/api")
//        `${import.meta.env.VITE_API_DOMAIN_WS}${this.token}`
//        trickleWebSocket = .init(url: URL(string: "?authToken=\()"), session: session)
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
