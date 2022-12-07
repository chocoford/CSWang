//
//  CSUserInfo.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/7.
//

import Foundation

struct CSUserInfo {
//    /// trickle member info
//    let name: String
//    let avatarURL: String
    
    // MARK: - app user info
    let immunityNum: Int
    let lastCleanDate: Date?
    let nextCleanDate: Date?
    
    // MARK: - game info (this week)
    struct GambleInfo {
        /// 从一年开始周数
        let weekNum: Int
        let score: Int
        let rank: Int?
        
        let absent: Bool
        /// 有可能被修改，如果有editAt，则视作无效
        let isValid: Bool
    }
    
    var roundGame: Loadable<GambleInfo?>
    var historyGames: [GambleInfo] = []
    
//name: String, avatarURL: String,
    init(immunityNum: Int = 0, lastCleanDate: Date? = nil, nextCleanDate: Date? = nil, roundGame: Loadable<GambleInfo?> = .notRequested) {
//        self.name = name
//        self.avatarURL = avatarURL
        self.immunityNum = immunityNum
        self.lastCleanDate = lastCleanDate
        self.nextCleanDate = nextCleanDate
        self.roundGame = roundGame
    }

//    init(from trickleInfo: MemberData) {
//        self.name = trickleInfo.name
//        self.avatarURL = trickleInfo.avatarURL
//    }
}

struct SummaryInfo {
    let week: Int
    let rankedParticipantIDsAndScores: [(String, Int)]
}
