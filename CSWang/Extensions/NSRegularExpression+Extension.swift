//
//  NSRegularExpression+Extension.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/14.
//

import Foundation

extension NSRegularExpression {
    func matches(_ string: String) -> Bool {
        let range = NSRange(location: 0, length: string.utf16.count)
        return firstMatch(in: string, options: [], range: range) != nil
    }
}
