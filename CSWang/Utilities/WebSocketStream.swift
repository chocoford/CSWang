//
//  WebSocketStream.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/10.
//

import Foundation
import OSLog

enum WebSocketStreamError: Error {
    case encodingError
}

class WebSocketStream: AsyncSequence {
    typealias Element = URLSessionWebSocketTask.Message
    typealias AsyncIterator = AsyncThrowingStream<URLSessionWebSocketTask.Message, Error>.Iterator
    func makeAsyncIterator() -> AsyncIterator {
        guard let stream = stream else {
             fatalError("stream was not initialized")
         }
         socket.resume()
         listenForMessages()
         return stream.makeAsyncIterator()
    }
    
    private let logger = Logger(subsystem: "CSWang", category: "WebSocketStream")
    
    private var stream: AsyncThrowingStream<Element, Error>?
    private var continuation: AsyncThrowingStream<Element, Error>.Continuation?
    private let socket: URLSessionWebSocketTask
    
    var status: URLSessionTask.State {
        socket.state
    }
    
    public var closeCode: String {
        String(describing: socket.closeCode)
    }
    
    public var closeReason: String {
        guard let reason = socket.closeReason else { return "Unknown" }
        let json = try? JSONSerialization.jsonObject(with: reason)
        return String(describing: json)
    }
    
    init(url: URL, session: URLSession = URLSession.shared) {
        logger.info("initing websocket: \(url.formatted())")
        socket = session.webSocketTask(with: url)
        socket.delegate = WebSocketStreamDelegate()
        
        stream = AsyncThrowingStream { continuation in
            self.continuation = continuation
            self.continuation?.onTermination = { @Sendable [socket] _ in
                socket.cancel()
            }
        }
    }
    
    func ping() {
        socket.sendPing { [weak self] error in
            if let error = error {
                self?.logger.error("ping error: \(error)")
            } else {
                self?.logger.info("pong!")
            }
        }
    }
    
    private func listenForMessages() {
        socket.receive { [unowned self] result in
            switch result {
            case .success(let message):
//                if let data = JSONSerialization.data(withJSONObject: message)
                continuation?.yield(message)
                listenForMessages()
            case .failure(let error):
                continuation?.finish(throwing: error)
            }
        }
    }
    
    private func waitForMessages() async {
        do {
            let message = try await socket.receive()
            continuation?.yield(message)
            await waitForMessages()
        } catch {
            continuation?.finish(throwing: error)
        }
    }
    
    public func send(data: Codable) async {
        socket.resume()
        do {
            logger.error("send data: \(String(describing: data))")
            let data = try JSONEncoder().encode(data)
            try await socket.send(.data(data))
        } catch {
            logger.error("\(error)")
        }
    }
    
    public func send(message: Codable) async {
        socket.resume()
        do {
            logger.error("send message: \(String(describing: message))")
            let data = try JSONEncoder().encode(message)
            guard let string = String(data: data, encoding: .utf8) else {
                throw WebSocketStreamError.encodingError
            }
            try await socket.send(.string(string))
        } catch {
            logger.error("\(error)")
        }
    }
    
    public func send(message: String) async {
        socket.resume()
        do {
            logger.error("send message: \(String(describing: message))")
            try await socket.send(.string(message))
        } catch {
            logger.error("\(error)")
        }
    }
    
}


class WebSocketStreamDelegate: NSObject, URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Web socket opened")
    }

    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Web socket closed")
        print(TrickleWebSocket.shared.stream?.closeCode, TrickleWebSocket.shared.stream?.closeReason)
    }
}
