//
//  Int+Extension.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/16.
//

import Foundation

extension Int {
    init?<T>(_ source: T?) where T : BinaryInteger {
        if source != nil {
            self = Int(source!)
        } else {
            return nil
        }
    }
    
    init?<T>(_ source: T?) where T : BinaryFloatingPoint {
        if source != nil {
            self = Int(source!)
        } else {
            return nil
        }
    }
}
