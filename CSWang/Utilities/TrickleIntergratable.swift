//
//  TrickleIntergratable.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/6.
//

import Foundation


struct Block: Codable {
    enum BlockType: String, Codable {
        case h1, h2, h3
        case richText = "rich_texts"
    }
    
    let id: String
    let type: BlockType
    let isFirst: Bool
    let indent: Int
    let blocks: [Block]
    let display: String
    let elements: [Element]
    let isCurrent: Bool
    let constraint: String
    
    init(type: BlockType, blocks: [Block], elements: [Element]) {
        self.id = UUID().uuidString
        self.type = type
        self.isFirst = true
        self.indent = 0
        self.blocks = blocks
        self.display = "block"
        self.elements = elements
        self.isCurrent = false
        self.constraint = "free"
    }
}

struct Element: Codable {
    enum ElementType: String, Codable {
        case text
    }
    
    let id, text: String
    let type: ElementType
    let elements: [Element]
    let isCurrent: Bool
}

struct TrickleIntergratable {
    enum PostType {
        case helloWorld
        case inviteMembers
    }
    
    static func createPost() -> [Block] {
        
        return []
    }
}
