//
//  Dictionary+Extension.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/8.
//

import Foundation
 
extension Dictionary {
    static func + (lhs: [Key : Value], rhs: Self) -> Self  {
//        var result: Self = rhs
//
//        for (key, value) in lhs {
//            result[key] = value
//        }
//
//        return result
        
        return rhs.merging(lhs) { (_, new) in
            new
        }
    }
}
