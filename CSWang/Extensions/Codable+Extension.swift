//
//  Encodable+Extension.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/1.
//

import Foundation

extension Encodable {
    subscript(key: String) -> Any? {
        return dictionary[key]
    }
    var dictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
    }
    
    var description: String {
//        guard let data = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted, .sortedKeys]),
//              let json = try? JSONSerialization.jsonObject(with: data) else {
//            return ""
//        }
        return String(describing: self)
    }
}



//extension JSONDecoder.DateDecodingStrategy {
//    static let multiple = custom {
//        let container = try $0.singleValueContainer()
//        do {
//            return try Date(timeIntervalSince1970: container.decode(Double.self))
//        } catch DecodingError.typeMismatch {
//            let string = try container.decode(String.self)
//            if let date = Formatter.iso8601withFractionalSeconds.date(from: string) ??
//                Formatter.iso8601.date(from: string) ??
//                Formatter.ddMMyyyy.date(from: string) {
//                return date
//            }
//            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
//        }
//    }
//}
