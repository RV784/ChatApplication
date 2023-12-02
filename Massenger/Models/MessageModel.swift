//
//  MessageModel.swift
//  Massenger
//
//  Created by Rajat verma on 02/12/23.
//

import Foundation
import MessageKit

struct Message: MessageType {
    var sender: MessageKit.SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKit.MessageKind
}

struct Sender: SenderType {
    var photoUrl: String
    var senderId: String
    var displayName: String
}
