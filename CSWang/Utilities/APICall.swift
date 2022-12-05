//
//  APICall.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 23.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import Foundation
import OSLog

protocol APICall {
    var path: String { get }
    var method: String { get }
    var headers: [String: String]? { get }
    func body() throws -> Data?
}

enum APIError: Swift.Error {
    case invalidURL
    case httpCode(HTTPCode, reason: String, headers: [AnyHashable: Any]?)
    case unexpectedResponse
    case imageDeserialization
    case parameterInvalid
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
            case .invalidURL: return "Invalid URL"
            case let .httpCode(code, reason, headers): return "Unexpected HTTP code: \(code), reason: \(reason), response headers: \(headers ?? [:])"
            case .unexpectedResponse: return "Unexpected response from the server"
            case .imageDeserialization: return "Cannot deserialize image from Data"
            case .parameterInvalid: return "Parameter invalid"
        }
    }
}

extension APICall {
    func urlRequest(baseURL: String) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        request.httpBody = try body()
        return request
    }
    
    func makeBody<T: Encodable>(payload: T) throws -> Data {
        let dic = payload.dictionary
        if JSONSerialization.isValidJSONObject(dic) {
            return try JSONSerialization.data(withJSONObject: dic,
                                              options: [.prettyPrinted, .fragmentsAllowed])
        } else {
            throw APIError.parameterInvalid
        }
    }
}

typealias HTTPCode = Int
typealias HTTPCodes = Range<HTTPCode>

extension HTTPCodes {
    static let success = 200 ..< 300
}
