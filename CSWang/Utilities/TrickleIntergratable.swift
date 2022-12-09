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
        case divider = "hr"
        case numberedList = "number_list"
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
    let userDefinedValue: String?
    
    init(type: BlockType, value: String? = nil, blocks: [Block] = [], elements: [Element]) {
        self.id = UUID().uuidString
        self.type = type
        self.isFirst = true
        self.indent = 0
        self.blocks = blocks
        self.elements = elements
        self.isCurrent = false
        self.constraint = "free"
        self.display = "block"
        self.userDefinedValue = value
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
        static func == (lhs: TrickleIntergratable.PostType, rhs: TrickleIntergratable.PostType) -> Bool {
            lhs.id == rhs.id
        }
        
        case helloWorld
        case membersChange(invitedMembers: [MemberData])
        case gamble(score: Int)
        case summary(memberAndScores: [(MemberData, Int)])
        
        var id: String {
            switch self {
                case .helloWorld:
                    return "hello world"
                    
                case .membersChange:
                    return "members changed"
                    
                case .gamble:
                    return "gamble"
                    
                case .summary:
                    return "summary"
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
        let calendar = Calendar.current
        let week = calendar.component(.weekOfYear, from: Date.now)
        
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
            case .gamble(let score):
                blocks += [
                    Block(type: .h3,
                          elements: [
                            Element(.text, text: "Week \(week)", value: String(week))
                          ]),
                    Block(type: .richText,
                          elements: [
                            Element(.text, text: "I get a score of \(score) in this round.", value: "\(score)")
                          ])
                ]
            case .summary(let memberAndScores):
                blocks += [
                    Block(type: .h3,
                          elements: [
                            Element(.text, text: "Week \(week) has finished!", value: String(week))
                          ]),
                    Block(type: .richText,
                          elements: [
                            Element(.text, text: "rank")
                          ]),
                    Block(type: .divider,
                          elements: [
                            Element(.text, text: "")
                          ])
                ] + memberAndScores.sorted(by: {$0.1 > $1.1}).enumerated().map { (index, tuple) in
                    Block(type: .numberedList,
                          value: "\(index + 1).",
                          elements: [
                            Element(.user, text: "\(tuple.0.name)", value: tuple.0.memberID),
                            Element(.text, text: " got a score of \(tuple.1)", value: "\(tuple.1)"),
                          ])
                }
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
                
            case PostType.gamble(score: 0).id:
                return PostType.gamble(score: 0)
                
            case PostType.summary(memberAndScores: []).id:
                return PostType.summary(memberAndScores: [])
                
            default:
                return nil
        }
    }
    
    static func getMembers(_ blocks: [Block], from members: [MemberData]) -> [MemberData] {
        guard getType(blocks) == .membersChange(invitedMembers: []) else {
            return []
        }
        guard blocks.count == 3 else {
            return []
        }
        guard let elements = blocks[2].elements else { return [] }
        let userElements = elements.suffix(elements.count - 1)
        let memberIDs = userElements.compactMap { $0.value }
        return members.filter { member in
            memberIDs.contains(member.memberID)
        }
    }
    
    static func getLatestSummary(trickles: [TrickleData]) -> SummaryInfo? {
        for trickle in trickles {
            if case .summary = TrickleIntergratable.getType(trickle.blocks) {
                continue
            }
            guard trickle.blocks.count > 3 else { continue }
            
            let weekBlock = trickle.blocks[1]
            guard weekBlock.type == .h3,
                  let weekElement = weekBlock.elements,
                  weekElement.count == 1,
                  let weekString = weekElement[0].value,
                  let week = Int(weekString) else {
                continue
            }
            
            var needContinue = false
            var resultRanks: [(String, Int)] = []
            for block in trickle.blocks.suffix(trickle.blocks.count - 2) {
                guard block.type == .numberedList else {
                    needContinue = true
                    break
                }
                
                guard let elements = block.elements,
                      elements.count == 2 else {
                    needContinue = true
                    break
                }
                
                let userElement = elements[0]
                guard let memberID = userElement.value else {
                    needContinue = true
                    break
                }
                let scoreElement = elements[1]
                guard let scoreString = scoreElement.value,
                      let score = Int(scoreString) else {
                    needContinue = true
                    break
                }
                
                resultRanks.append((memberID, score))
            }
            if needContinue {
                continue
            }
            
            return .init(week: week,
                         rankedParticipantIDsAndScores: resultRanks)
        }
        return nil
    }
    
//    static func getLatestGameInfo(from trickles: [TrickleData]) -> CSUserInfo.GambleInfo? {
//        guard let post = trickles.first(where: {
//            TrickleIntergratable.getType($0.blocks)?.id == TrickleIntergratable.PostType.gamble(score: 0).id
//        }) else {
//            return nil
//        }
//        guard let gameInfo = TrickleIntergratable.extractGameInfo(post) else {
//            return nil
//        }
//
//        if gameInfo.weekNum == currentWeek {
//            return .init(weekNum: gameInfo.weekNum,
//                         score: gameInfo.score,
//                         rank: nil,
//                         absent: false,
//                         isValid: true)
//        } else {
//            return nil
//        }
//    }
    
    static func extractGameInfo(_ trickle: TrickleData) -> CSUserInfo.GambleInfo? {
        let blocks = trickle.blocks
        guard case .gamble = getType(blocks) else {
            return nil
        }
        guard blocks.count == 3 else {
            return nil
        }
        let weekBlock = blocks[1]
        guard weekBlock.type == .h3,
              let weekElement = weekBlock.elements,
              weekElement.count == 1,
              let weekString = weekElement[0].value,
              let week = Int(weekString) else {
            return nil
        }
        
        guard let scoreElements = blocks[2].elements,
              scoreElements.count == 1,
              let value = scoreElements[0].value,
              let score = Int(value) else { return nil }

        return .init(memberData: trickle.authorMemberInfo,
                     weekNum: week,
                     score: score,
                     absent: false,
                     isValid: trickle.editAt == nil)
    }
    
    static func roundGamesNum(_ trickles: [TrickleData]) -> Int {
        let trickles = trickles.filter {
            getWeek(second: $0.createAt) == currentWeek
        }
        return trickles.count
    }
    
    static func getWeeklyGameInfos(_ trickles: [TrickleData]) -> [CSUserInfo.GambleInfo] {
        let weeklyGambleTrickles = trickles.filter {
            if getWeek(second: $0.createAt) == currentWeek,
               case .gamble = getType($0.blocks) {
                return true
            }
            return false
        }
            .removeDuplicate(keyPath: \.authorMemberInfo.memberID)
        
        return weeklyGambleTrickles.compactMap {
            extractGameInfo($0)
        }
    }
}
