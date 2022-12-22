//
//  TrickleSocketRepository.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/10.
//

import Foundation
import OSLog
import Combine

class TrickleWebSocket {
    static var shared: TrickleWebSocket = .init()
    
    let logger = Logger(subsystem: "CSWang", category: "TrickleWebSocket")
    
    var stream: WebSocketStream? = nil
    var socketSession: URLSession = .shared
        
    var token: String? = nil
    var userID: String? = nil
    
    var configs: ConnectData? {
        willSet {
            guard let configs = configs else { return }
            for timers in self.timers.values {
                timers.invalidAll()
            }
            timers[configs.connectionID] = nil
        }
    }
    
    struct Timers {
        var helloInterval: Timer?
        var deadCountdown: Timer?
        var ping: Timer?
        var roomHello: Timer?
        var roomDead: Timer?
        
        func invalidAll() {
            helloInterval?.invalidate()
            deadCountdown?.invalidate()
            ping?.invalidate()
            roomHello?.invalidate()
            roomDead?.invalidate()
        }
    }
    var timers: [String : Timers] = [:]
    
    var workspaceID: String?
    var memberID: String?
    
    var changeNotifyPulisher: PassthroughSubject<Void, Never> = .init()
    
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
    
    private func send(_ message: MessageType) async {
        switch message {
            case .connect:
                await stream?.send(message: OutgoingEmptyMessage(action: .message, path: .connect))
            case .hello(let data):
                await stream?.send(message: OutgoingMessage(action: .message, path: .hello, data: data))
                
            case .joinRoom(let data):
                await stream?.send(message: OutgoingMessage(action: .message, path: .joinRoom, data: data))
                
            case .roomStatus(let data):
                await stream?.send(message: OutgoingMessage(action: .message, path: .roomStatus, data: data))
                
            case .leaveRoom(let data):
                await stream?.send(message: OutgoingMessage(action: .message, path: .leaveRoom, data: data))
        }
    }
    
    public func close() {
        Task {
            if let workspaceID = workspaceID,
               let memberID = memberID {
               await leaveRoom(workspaceID: workspaceID, memberID: memberID)
            }
            timers.values.forEach { timer in
                timer.invalidAll()
            }
        }
    }
}

extension TrickleWebSocket {
    public func joinRoom(workspaceID: String, memberID: String) async {
        let workspaceID = "workspace:" + workspaceID
        self.workspaceID = workspaceID
        self.memberID = memberID
        await send(.joinRoom(data: .init(roomID: workspaceID, memberID: memberID, status: .online)))
    }
    
    public func leaveRoom(workspaceID: String, memberID: String) async {
        let workspaceID = "workspace:" + workspaceID
        self.workspaceID = nil
        self.memberID = nil
        await send(.leaveRoom(data: .init(roomID: workspaceID, memberID: memberID, status: .offline)))

    }
}

// MARK: - Message Payload
extension TrickleWebSocket {
    enum MessageType {
        case connect

        case hello(data: HelloData)

        case joinRoom(data: RoomData)
        case roomStatus(data: RoomData)
        case leaveRoom(data: RoomData)
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
        case roomMembers = "room_members"
        
        /// actions
        case sync
        case changeNotify = "change_notify"
    }
    typealias IncomingEmptyMessage = IncomingMessage<EmptyData>
    typealias IncomingMessage<T: Codable> = Message<T, IncomingMessagePath>
    
    enum OutgoingMessagePath: String, Codable {
        case connect
        case hello = "connect_hello"
        case joinRoom = "join_room"
        case roomStatus = "room_status"
        case leaveRoom = "leave_room"
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
        guard let rawPath = msgDic["path"] as? String else {
            logger.error("invalid path. Message: \(msgDic)")
            return
        }
        switch IncomingMessagePath(rawValue: rawPath) {
            case .connectSuccess:
                guard let messageData = message.decode(IncomingMessage<[ConnectData]>.self) else { fallthrough }
                logger.info("on connect: \(messageData.description)")
                onConnect(messageData)
                
            case .helloAck:
                guard let messageData = message.decode(IncomingMessage<HelloAckData>.self) else { fallthrough }
                logger.info("on hello ack: \(messageData.description)")
                onHelloAck(messageData)
            case .joinRoomAck:
                guard let messageData = message.decode(IncomingEmptyMessage.self) else { fallthrough }
                logger.info("on join room ack: \(messageData.description)")
                onJoinRoomAck(messageData)
                            
            case .roomMembers:
                guard let messageData = message.decode(IncomingMessage<[RoomMembers]>.self) else { fallthrough }
                logger.info("on room members: \(messageData.description)")
                
            case .sync:
                guard let _ = message.decode(IncomingMessage<[RoomMembers]>.self) else { fallthrough }
                
            case .changeNotify:
                guard let messageData = message.decode(IncomingMessage<[ChangeNotifyData]>.self) else { fallthrough }
                logger.info("on change notify: \(messageData.description)")
                guard let _ = messageData.data?.first?.codes.keys.first(where: {
                    if #available(iOS 16.0, macOS 13.0, *) {
                        return $0.firstMatch(of: /workspace:[0-9]+:trickle/) != nil
                    } else {
                        return $0.matches(regex: "workspace:[0-9]+:trickle")
                    }
                }) else {
                    break
                }
                onChangeNotify()
                
            case .none:
                logger.error("Unhandled message: \(msgDic)")
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
    
    
    private func onJoinRoomAck(_ data: IncomingEmptyMessage) {
        guard let configs = self.configs else { return }
        DispatchQueue.main.async {
            /// 开启`room_status_hello`机制
            let helloTimer = Timer.scheduledTimer(withTimeInterval: Double(self.configs?.roomStatusHelloInterval ?? 30),
                                                  repeats: true) { timer in
                Task {
                    guard let workspaceID = self.workspaceID,
                          let memberID = self.memberID else {
                        return
                    }
                    await self.send(.roomStatus(data: .init(roomID: workspaceID, memberID: memberID, status: .online)))
                }
            }
            self.timers[configs.connectionID]?.roomHello = helloTimer
        }
    }
    
    private func onChangeNotify() {
        DispatchQueue.main.async {
            self.changeNotifyPulisher.send()
        }
    }
}

// MARK: - internal interface
private extension TrickleWebSocket {
    typealias Configs = ConnectData
}

extension TrickleWebSocket.MessageType {
    struct HelloData: Codable {
        let userID: String
        enum CodingKeys: String, CodingKey {
            case userID = "userId"
        }
    }
    
    struct RoomData: Codable {
        let roomID, memberID: String
        enum Status: String, Codable {
            case online
            case offline
        }
        let status: Status
        
        enum CodingKeys: String, CodingKey {
            case roomID = "roomId"
            case memberID = "memberId"
            case status
        }
    }
}

// MARK: - Incoming Socket Data
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
    
    struct RoomMembers: Codable {
        struct RoomMembersUpdate: Codable {
            let memberID: String
            let roomID: String
            let type: String
            
            enum CodingKeys: String, CodingKey {
                case memberID = "memberId"
                case roomID = "roomId"
                case type
            }
        }
        
        let all: [String : [String]]
        let update: RoomMembersUpdate
    }
    
    struct ChangeNotifyData: Codable {
        let codes: [String : CodeData]

        struct CodeData: Codable {
            let version: Int
            let latestChangeEvent: LatestChangeEvent
            let trigger: Trigger
        }

        struct LatestChangeEvent: Codable {
            let event: String
            
            // don't care
//            let eventData: EventData
        }
        
        struct Trigger: Codable {
            let trickleTraceID: String

            enum CodingKeys: String, CodingKey {
                case trickleTraceID = "trickleTraceId"
            }
        }


        // MARK: - EventData
        struct EventData: Codable {
            let trickleID, title, authorMemberID: String
            let mentionedMemberIDS: [String]
            let receiverType, receiverID, workspaceID: String
            let createAt: Int
            let threadID, prevTrickleID, appMemberID: String?

            enum CodingKeys: String, CodingKey {
                case trickleID = "trickleId"
                case title
                case authorMemberID = "authorMemberId"
                case mentionedMemberIDS = "mentionedMemberIds"
                case receiverType
                case receiverID = "receiverId"
                case workspaceID = "workspaceId"
                case createAt
                case threadID = "threadId"
                case prevTrickleID = "prevTrickleId"
                case appMemberID = "appMemberId"
            }
        }
    }
}
