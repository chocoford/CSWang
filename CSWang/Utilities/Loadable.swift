//
//  Loadable.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/4.
//

import Foundation
import SwiftUI

enum LoadableError: Error, LocalizedError {
    case cancelled
    case notFound
    case unexpected(error: Error)
    
    var localized: String {
        switch self {
            case .cancelled:
                return "Canceled by user."
            case .notFound:
                return "Entity not found."
            case .unexpected(let error):
                return error.localizedDescription
        }
    }
}

enum Loadable<T> {
    case notRequested
    case isLoading(last: T?) //, cancelBag: CancelBag
    case loaded(data: T)
    case failed(LoadableError)

    var value: T? {
        switch self {
        case let .loaded(value): return value
        case let .isLoading(last): return last
        default: return nil
        }
    }
    var error: LoadableError? {
        switch self {
        case let .failed(error): return error
            default: return nil
        }
    }
    
    enum State {
        case notRequested
        case isLoading
        case loaded
        case failed
    }
    
    var state: State {
        switch self {
            case .notRequested:
                return .notRequested
            case .isLoading:
                return .isLoading
            case .loaded:
                return .loaded
            case .failed:
                return .failed
        }
    }
}

extension Loadable {
    
    mutating func setIsLoading() { //cancelBag: CancelBag
        self = .isLoading(last: value) //, cancelBag: cancelBag
    }
    
    mutating func cancelLoading() {
        switch self {
            case let .isLoading(last): //, cancelBag
//                cancelBag.cancel()
                if let last = last {
                    self = .loaded(data: last)
                } else {
                    let error = NSError(
                        domain: NSCocoaErrorDomain, code: NSUserCancelledError,
                        userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Canceled by user",
                                                                                comment: "")])
                    self = .failed(.unexpected(error: error))
                }
            default: break
        }
    }
    
    func map<V>(_ transform: (T) throws -> V) -> Loadable<V> {
        do {
            switch self {
                case .notRequested: return .notRequested
                case let .failed(error): return .failed(error)
                case let .isLoading(value):
                    return .isLoading(last: try value.map { try transform($0) })
                case let .loaded(value):
                    return .loaded(data: try transform(value))
            }
        } catch {
            return .failed(.unexpected(error: error))
        }
    }
}
//protocol SomeOptional {
//    associatedtype Wrapped
//    func unwrap() throws -> Wrapped
//}
//
//struct ValueIsMissingError: Error {
//    var localizedDescription: String {
//        NSLocalizedString("Data is missing", comment: "")
//    }
//}
//
//extension Optional: SomeOptional {
//    func unwrap() throws -> Wrapped {
//        switch self {
//        case let .some(value): return value
//        case .none: throw ValueIsMissingError()
//        }
//    }
//}
//
//extension Loadable where T: SomeOptional {
//    func unwrap() -> Loadable<T.Wrapped> {
//        map { try $0.unwrap() }
//    }
//}

extension Loadable: Equatable where T: Equatable {
    static func == (lhs: Loadable<T>, rhs: Loadable<T>) -> Bool {
        switch (lhs, rhs) {
        case (.notRequested, .notRequested): return true
        case let (.isLoading(lhsV), .isLoading(rhsV)): return lhsV == rhsV
        case let (.loaded(lhsV), .loaded(rhsV)): return lhsV == rhsV
        case let (.failed(lhsE), .failed(rhsE)):
            return lhsE.localizedDescription == rhsE.localizedDescription
        default: return false
        }
    }
}
