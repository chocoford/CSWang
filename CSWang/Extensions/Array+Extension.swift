//
//  Array+Extenxion.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/2.
//

import Foundation

extension Array {
    func formDictionary(key: KeyPath<Self.Element, String>) -> [String: Self.Element] {
        var dic: [String : Self.Element] = [:]
        for item in self {
            dic[item[keyPath: key]] = item
        }
        return dic
    }
    
    /// ignore duplicate keys in array
    func removeDuplicate(keyPath: KeyPath<Self.Element, String>) -> Self {
        var set = Set<String>()
        var results: Self = []
        for item in self {
            let key = item[keyPath: keyPath]
            guard !set.contains(key) else { continue }
            set.insert(key)
            results.append(item)
        }
        return results
    }
}

