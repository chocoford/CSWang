//
//  WebRepository.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 23.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import Foundation
import Combine
import OSLog

protocol WebRepository {
    var logger: Logger { get }
    var session: URLSession { get }
    var baseURL: String { get }
    var bgQueue: DispatchQueue { get }
}

extension WebRepository {
    func call<Value>(endpoint: APICall, httpCodes: HTTPCodes = .success) -> AnyPublisher<Value, Error>
        where Value: Decodable {
            logger.log("calling \(endpoint.method) \(endpoint.path)") //; \nHeaders: \(endpoint.headers ?? [:])
            if let body = try? endpoint.body() {
                do {
                    let payload = try JSONSerialization.jsonObject(with: body)
                    logger.log("body: \(String(describing: payload))")
                } catch {
                    logger.error("can not serialize body")
                }
            }
        do {
            let request = try endpoint.urlRequest(baseURL: baseURL)
            return session
                .dataTaskPublisher(for: request)
                .map({ (data, res) in
                    let json = try? JSONSerialization.jsonObject(with: data, options: [])
                    if let objJson = json as? [String: Any] {
                        logger.debug("json(object): \(objJson.debugDescription)")
                    } else if
                        let arrJson = json as? [[String: Any]] {
                        logger.debug("json(array): \(arrJson.debugDescription)")
                    }
                    return (data, res)
                })
                .eraseToAnyPublisher()
                .requestJSON(httpCodes: httpCodes)
                .mapError {
                    logger.error("\($0.localizedDescription)")
                    return $0
                }
                .eraseToAnyPublisher()
        } catch let error {
            logger.error("\(error.localizedDescription)")
            return Fail<Value, Error>(error: error).eraseToAnyPublisher()
        }
    }
}

// MARK: - Helpers

extension Publisher where Output == URLSession.DataTaskPublisher.Output {
    func requestData(httpCodes: HTTPCodes = .success) -> AnyPublisher<Data, Error> {
        return tryMap {
                assert(!Thread.isMainThread)
                guard let code = ($0.1 as? HTTPURLResponse)?.statusCode else {
                    throw APIError.unexpectedResponse
                }
                guard httpCodes.contains(code) else {
                    throw APIError.httpCode(code,
                                            reason: "\(try? JSONSerialization.jsonObject(with: $0.data, options: []))",
                                            headers: ($0.response as? HTTPURLResponse)?.allHeaderFields)
                }
                return $0.0
            }
//            .extractUnderlyingError()
            .eraseToAnyPublisher()
    }
}

private extension Publisher where Output == URLSession.DataTaskPublisher.Output {
    func requestJSON<Value>(httpCodes: HTTPCodes) -> AnyPublisher<Value, Error> where Value: Decodable {
        return requestData(httpCodes: httpCodes)
            .decode(type: Value.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
