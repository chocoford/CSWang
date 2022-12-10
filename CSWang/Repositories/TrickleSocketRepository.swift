//
//  TrickleSocketRepository.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/10.
//

import Foundation

class TrickleWebSocket {
    static var shared: TrickleWebSocket = .init()
    
    var stream: WebSocketStream? = nil
    var socketSession: URLSession = .shared
    
    func initSocket(token: String) {
        guard let url = URL(string: "wss://devwsapi.trickle.so?authToken=Bearer%20\(token)") else { return }
        stream = .init(url: url, session: socketSession)
        Task {
            await sendHello()
        }
    }
    
    func sendHello() async {
        await stream?.sendMessage(message: MessageData.initialize(action: .message, path: .connect))
    }
    
    
    func handleMessage(message: String) {
        
    }
}

protocol TrickleWebSocketMessage: Codable {
    var id: String { get }
    var action: String { get }
    var path: String { get }
    var authorization: String { get }
}

extension TrickleWebSocket {
    struct EmptyData: Codable {}
    struct MessageData<T: Codable>: Codable {
        
        enum Action: String, Codable {
            case message
            case notification
            case version
        }
        
        enum Path: String, Codable {
            case connect
            case joinRoom = "join_room"
            case joinRoomAck = "join_room_ack"
        }
        
        let id: String
        let authorization: String?
        let action: Action
        let path: Path
        let data: T?
        
        private init(id: String? = nil, authorization: String? = nil, action: Action, path: Path, data: T? = nil) {
            self.id = id ?? UUID().uuidString
            self.authorization = authorization ?? formBearer(with: AuthMiddleware.shared.token)
            self.action = action
            self.path = path
            self.data = data
        }
        
        static func initialize(id: String? = nil, authorization: String? = nil, action: Action, path: Path, data: T) -> MessageData<T> {
            return MessageData(id: id,
                               authorization: authorization,
                               action: action,
                               path: path,
                               data: data)
        }
        
        static func initialize(id: String? = nil, authorization: String? = nil, action: Action, path: Path) -> MessageData<T> where T == EmptyData {
            return MessageData<T>(id: id,
                                  authorization: authorization,
                                  action: action,
                                  path: path)
        }
    }
    
    struct ConnectMessage: TrickleWebSocketMessage {
        var id: String = UUID().uuidString
        var action: String = "message"
        var path: String = "connect"
        var authorization: String
    }
}
