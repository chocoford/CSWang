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
}
