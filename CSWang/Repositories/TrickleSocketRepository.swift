//
//  TrickleSocketRepository.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/10.
//

import Foundation
import OSLog

class TrickleWebSocket {
    static var shared: TrickleWebSocket = .init()
    
    let logger = Logger(subsystem: "CSWang", category: "TrickleWebSocket")
    
    var stream: WebSocketStream? = nil
    var socketSession: URLSession = .shared
        
    var token: String? = nil
    var userID: String? = nil
    
    var configs: ConnectData? {
        willSet(val) {
            print("will set configs to \(val)")
        }
    }
    
    struct Timers {
        var helloInterval: Timer?
        var deadCountdown: Timer?
        var ping: Timer?
    }
    var timers: [String : Timers] = [:]
    
    func initSocket(token: String, userID: String) {
        self.token = token
        self.userID = userID
        guard let url = URL(string: "wss://devwsapi.trickle.so?authToken=Bearer%20\(token)") else { return }
        stream = .init(url: url, session: socketSession)
        Task {
            await send(.connect)
            /// handle internal messages
            do {
                for try await message in stream! {
                    handleMessage(message)
                }
            } catch {
                logger.error("\(error.localizedDescription)")
            }
            
        }
    }
    
    private func reinitSocket() {
        guard let token = self.token,
              let userID = self.userID else { return }
        self.initSocket(token: token, userID: userID)
    }
    
    public func send(_ message: MessageType) async {
        switch message {
            case .connect:
                await stream?.send(message: OutgoingEmptyMessage(action: .message, path: .connect))
            case .hello(let data):
                await stream?.send(message: OutgoingMessage(action: .message, path: .hello, data: data))
                
            case .joinRoom(let data):
                await stream?.send(message: OutgoingMessage(action: .message, path: .connect, data: data))
        }
    }
}

// MARK: - Message Payload
extension TrickleWebSocket {
    enum MessageType {
        case connect
        
        struct HelloData: Codable {
            let userID: String
            enum CodingKeys: String, CodingKey {
                case userID = "userId"
            }
        }
        case hello(data: HelloData)
        
        struct JoinRoomData: Codable {
            
        }
        case joinRoom(data: JoinRoomData)
    }

    enum MessageAction: String, Codable {
        case message
        case notification
        case version
    }
    
    struct Message<T: Codable, P: Codable>: Codable {
        let id: String
        let authorization: String?
        let action: MessageAction
        let path: P
        let data: T?

        init(id: String? = nil, authorization: String? = nil, action: MessageAction, path: P, data: T? = nil) {
            self.id = id ?? UUID().uuidString
            self.authorization = authorization ?? formBearer(with: AuthMiddleware.shared.token)
            self.action = action
            self.path = path
            self.data = data
        }
    }

    enum IncomingMessagePath: String, Codable {
        case connectSuccess = "connect_success"
        case helloAck = "connect_hello_ack"
        case joinRoomAck = "join_room_ack"
    }
    typealias IncomingEmptyMessage = IncomingMessage<EmptyData>
    typealias IncomingMessage<T: Codable> = Message<T, IncomingMessagePath>
    
    enum OutgoingMessagePath: String, Codable {
        case connect
        case hello = "connect_hello"
        case joinRoom = "join_room"
    }
    typealias OutgoingEmptyMessage = OutgoingMessage<EmptyData>
    typealias OutgoingMessage<T: Codable> = Message<T, OutgoingMessagePath>
    
}

// MARK: - Handle Message
extension TrickleWebSocket {
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
            case .data:
                fatalError()
            case .string(let string):
                handleMessage(string)
            @unknown default:
                fatalError()
        }
    }
    private func handleMessage(_ message: String) {
        let msgDic = message.toJSON() ?? [:]
        logger.info("on message: \(msgDic)")
        guard let rawPath = msgDic["path"] as? String else {
            logger.error("invalid path")
            return
        }
        switch IncomingMessagePath(rawValue: rawPath) {
            case .connectSuccess:
                guard let messageData = message.decode(IncomingMessage<[ConnectData]>.self) else { return }
                logger.info("on connect.")
                onConnect(messageData)
                
            case .helloAck:
                guard let messageData = message.decode(IncomingMessage<HelloAckData>.self) else { return }
                logger.info("on hello ack.")
                onHelloAck(messageData)
            case .joinRoomAck:
                break
                            
            case .none:
                logger.error("invalid path")
        }
    }
    
    private func onConnect(_ data: IncomingMessage<[ConnectData]>) {
        guard let data = data.data?.first else {
            logger.error("invalid data")
            return
        }
        self.configs = data
        timers[data.connectionID] = .init()
        /// timer must initialize in main loop
        DispatchQueue.main.async {
            /// 开启hello机制
            let helloTimer = Timer.scheduledTimer(withTimeInterval: Double(data.helloInterval),
                                                  repeats: true) { timer in
                Task {
                    await self.send(.hello(data: .init(userID: self.userID ?? "")))
                }
            }
            self.timers[data.connectionID]?.helloInterval = helloTimer
            
//            /// 同时开启10秒一次的ping
//            let pingTimer = Timer.scheduledTimer(withTimeInterval: 10,
//                                                 repeats: true) { timer in
//                self.stream?.ping()
//            }
//            
//            self.timers[data.connectionID]?.ping = pingTimer
        }
    }
    
    private func onHelloAck(_ data: IncomingMessage<HelloAckData>) {
        guard let _ = data.data else { return }
//        self.configs?.connectionID = data.connectionID
        setDeadTimer()
    }
    
    private func setDeadTimer() {
        guard let configs = configs else { return }
        timers[configs.connectionID]?.deadCountdown?.invalidate()
        let dead = Timer.scheduledTimer(withTimeInterval: Double(configs.deadInterval),
                             repeats: false) { timer in
            self.reinitSocket()
        }
        timers[configs.connectionID]?.deadCountdown = dead
    }
    
}

// MARK: - internal interface
private extension TrickleWebSocket {
    typealias Configs = ConnectData
}

extension TrickleWebSocket {
    struct ConnectData: Codable {
        var connectionID: String
        let helloInterval, deadInterval, maxRetryConnection, retryConnectionInterval: Int
        let roomStatusHelloInterval, roomStatusDeadInterval, joinRoomMaxRetryCounts, joinRoomMaxRetryInterval: Int
        let listRoomInterval: Int
        
        enum CodingKeys: String, CodingKey {
            case connectionID = "connectionId"
            case helloInterval = "hello_interval"
            case deadInterval = "dead_interval"
            case maxRetryConnection = "max_retry_connection"
            case retryConnectionInterval = "retry_connection_interval"
            case roomStatusHelloInterval = "room_status_hello_interval"
            case roomStatusDeadInterval = "room_status_dead_interval"
            case joinRoomMaxRetryCounts = "join_room_max_retry_counts"
            case joinRoomMaxRetryInterval = "join_room_max_retry_interval"
            case listRoomInterval = "list_room_interval"
        }
    }
    
    struct HelloAckData: Codable {
        let connectionID: String
        
        enum CodingKeys: String, CodingKey {
            case connectionID = "connId"
        }
    }
}
