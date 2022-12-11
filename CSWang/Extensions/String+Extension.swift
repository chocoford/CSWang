//
//  String+Extension.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/11.
//

import Foundation
extension String {
    func toJSON() -> [String: Any]? {
        guard let data = self.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: [.mutableContainers]) as? [String: Any]
    }
    
    func decode<T: Decodable>(_ type: T.Type) -> T? {
        guard let data = self.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type.self, from: data)
    }
    
    func snakeCased() -> Self {
       let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
       let fullWordsPattern = "([a-z])([A-Z]|[0-9])"
       let digitsFirstPattern = "([0-9])([A-Z])"
       return self.processCamelCaseRegex(pattern: acronymPattern)?
         .processCamelCaseRegex(pattern: fullWordsPattern)?
         .processCamelCaseRegex(pattern:digitsFirstPattern)?.lowercased() ?? self.lowercased()
     }

     fileprivate func processCamelCaseRegex(pattern: String) -> Self? {
       let regex = try? NSRegularExpression(pattern: pattern, options: [])
       let range = NSRange(location: 0, length: count)
       return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
     }
}
