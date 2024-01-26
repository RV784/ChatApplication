//
//  ConversationsModel.swift
//  Massenger
//
//  Created by Rajat verma on 29/12/23.
//

import Foundation

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}
