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
        
        enum CodingKeys: String, CodingKey {
            case h1, h2, h3
            case richText = "rich_texts"
        }
    }
    
    let id: String
    let type: BlockType
    let isFirst: Bool
    let indent: Int
    let blocks: [Block]?
    let elements: [Element]?
    let isCurrent: Bool
    let constraint: String
    let display: String
    
    init(type: BlockType, blocks: [Block] = [], elements: [Element]) {
        self.id = UUID().uuidString
        self.type = type
        self.isFirst = true
        self.indent = 0
        self.blocks = blocks
        self.elements = elements
        self.isCurrent = false
        self.constraint = "free"
        self.display = "block"
    }
}

struct Element: Codable {
    enum ElementType: String, Codable {
        case text
        case inlineCode = "inline_code"
        case user
    }
    
    let id, text: String
    let type: ElementType
    let value: String?
    let elements: [Element]?
    let isCurrent: Bool
    
    init(_ type: ElementType, text: String, value: String? = nil) {
        self.id = UUID().uuidString
        self.text = text
        self.type = type
        self.elements = []
        self.isCurrent = false
        self.value = value
    }
}

struct TrickleIntergratable {
    enum PostType: Identifiable, Equatable {
        case helloWorld
        case membersChange(invitedMembers: [MemberData])
        
        var id: String {
            switch self {
                case .helloWorld:
                    return "hello world"
                    
                case .membersChange:
                    return "members changed"
            }
        }
    }
    
    private static func generateIdentifier(_ type: PostType) -> Block {
        return Block(type: .richText,
                     elements: [
                        Element(.inlineCode, text: type.id)
                     ])
    }
    
    static func createPost(type: PostType) -> [Block] {
        var blocks: [Block] = [
            generateIdentifier(type)
        ]
        switch type {
            case .helloWorld:
                blocks += [
                    Block(type: .richText,
                          elements: [
                            Element(.text, text: "Hi, everyone. I'm in now!")
                          ])
                ]
            case .membersChange(let invitedMembers):
                blocks += [
                    Block(type: .richText,
                          elements: [
                            Element(.text, text: "I have invited new members.")
                          ]),
                    Block(type: .richText,
                          elements: [
                            Element(.text, text: "Now our team includes")
                          ] + invitedMembers.flatMap {
                              [
                                Element(.user, text: $0.name, value: $0.memberID),
                                Element(.text, text: " ")
                              ]
                          }),
                ]
        }
        return blocks
    }
    
    static func getType(_ blocks: [Block]) -> PostType? {
        guard let block = blocks.first else { return nil }
        guard let element = block.elements?.first,
              block.elements?.count == 1 else { return nil }
        guard element.type == .inlineCode else { return nil }
        switch element.text {
            case PostType.helloWorld.id:
                return PostType.helloWorld
                
            case PostType.membersChange(invitedMembers: []).id:
                return PostType.membersChange(invitedMembers: [])
                
            default:
                return nil
        }
    }
    
    static func getMembers(_ blocks: [Block], from members: [MemberData]) -> [MemberData] {
        guard getType(blocks) == .membersChange(invitedMembers: []) else {
            return []
        }
        guard blocks.count > 2 else {
            return []
        }
        guard let elements = blocks[2].elements else { return [] }
        let userElements = elements.suffix(elements.count - 1)
        let memberIDs = userElements.compactMap { $0.value }
        return members.filter { member in
            memberIDs.contains(member.memberID)
        }
    }
}
