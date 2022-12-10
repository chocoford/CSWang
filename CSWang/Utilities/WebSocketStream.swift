//
//  WebSocketStream.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/10.
//

import Foundation

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
    
    
    private var stream: AsyncThrowingStream<Element, Error>?
    private var continuation: AsyncThrowingStream<Element, Error>.Continuation?
    private let socket: URLSessionWebSocketTask
    
    init(url: URL, session: URLSession = URLSession.shared) {
        socket = session.webSocketTask(with: url)
        stream = AsyncThrowingStream { continuation in
            self.continuation = continuation
            self.continuation?.onTermination = { @Sendable [socket] _ in
                socket.cancel()
            }
        }
    }
    
    private func listenForMessages() {
        socket.receive { [unowned self] result in
            switch result {
            case .success(let message):
                continuation?.yield(message)
                listenForMessages()
            case .failure(let error):
                continuation?.finish(throwing: error)
            }
        }
    }
}
