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
}
