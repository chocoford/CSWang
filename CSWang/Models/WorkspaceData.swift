//
//  WorkspaceData.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/21.
//

import Foundation

// MARK: - Workspace Data
struct WorkspaceData: Codable, Hashable {
    let workspaceID: String
    let ownerID, name: String
    let memberNum, removedMemberNum: Int
    let logo, domain: String
    let userID: String
    let createAt, updateAt: Date
    let userMemberInfo: MemberData
    
    enum CodingKeys: String, CodingKey {
        case workspaceID = "workspaceId"
        case ownerID = "ownerId"
        case name, memberNum, removedMemberNum, logo, domain
        case userID = "userId"
        case createAt, updateAt, userMemberInfo
    }
}

extension WorkspaceData: Identifiable {
    var id: String {
        workspaceID
    }
}


struct WorkspaceGroupsData: Codable {
    let team: [GroupData]
    let personal: [GroupData]
}

// MARK: - GroupData
struct GroupData: Codable, Equatable {
    let groupID, ownerID, name, channelType: String
    let icon: String
    let isWorkspacePublic: Bool
    let createAt, updateAt: Date?
//    let channelSpace: ChannelSpace
//    let viewInfo: [ViewInfo]
//    let fieldInfo: [FieldInfo]

    enum CodingKeys: String, CodingKey {
        case groupID = "groupId"
        case ownerID = "ownerId"
        case name, channelType, icon, isWorkspacePublic, createAt, updateAt
//        case channelSpace, viewInfo, fieldInfo
    }
}



// MARK: - MemberData
struct MemberData: Codable, Hashable {
    let name, role, status, memberID, avatarURL: String
    let email: String?
    let createAt, updateAt: Date?

    enum CodingKeys: String, CodingKey {
        case name, role, email, status
        case memberID = "memberId"
        case avatarURL = "avatarUrl"
        case createAt, updateAt
    }
}


// MARK: - TrickleData
struct TrickleData: Codable, Equatable {
    let trickleID: String
    let authorMemberInfo: MemberData
//    let receiverInfo: ReceiverInfo
    let createAt, updateAt: Date
    let editAt: Date?
    let title: String
    let blocks: [Block]
//    let tagInfo, mentionedMemberInfo: [JSONAny]
//    let isPublic, allowGuestMemberComment, allowGuestMemberReact, allowWorkspaceMemberComment: Bool
//    let allowWorkspaceMemberReact: Bool
//    let likeCounts, commentCounts: Int
//    let hasLiked: Bool
//    let latestLikeMemberInfo, commentInfo, referTrickleInfo, reactionInfo: [JSONAny]
//    let viewedMemberInfo: ViewedMemberInfo
//    let threadID: JSONNull?

    enum CodingKeys: String, CodingKey {
        case trickleID = "trickleId"
        case authorMemberInfo, createAt, updateAt, editAt, title, blocks
//        , isPublic, allowGuestMemberComment, allowGuestMemberReact, allowWorkspaceMemberComment, allowWorkspaceMemberReact, likeCounts, commentCounts, hasLiked
//        case receiverInfo, tagInfo, latestLikeMemberInfo, viewedMemberInfo, commentInfo, referTrickleInfo, reactionInfo,
//        case threadID = "threadId"
    }
}
