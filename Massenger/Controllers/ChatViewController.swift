//
//  ChatViewController.swift
//  Massenger
//
//  Created by Rajat verma on 02/12/23.
//

import UIKit
import MessageKit

class ChatViewController: MessagesViewController {
    
    private var messages = [Message]()
    private var selfSender = Sender(photoUrl: "", senderId: "1", displayName: "Rajat")

    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        messages.append(.init(sender: selfSender,
                              messageId: "1",
                              sentDate: Date(),
                              kind: .text("Hello World message"))
        )
        
        messages.append(.init(sender: selfSender,
                              messageId: "1",
                              sentDate: Date(),
                              kind: .text("Lmao this is weird"))
        )
    }
}

// MARK: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    // Who the current sender is?
    func currentSender() -> MessageKit.SenderType {
        selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        // Messages array is a collection of messages
        // MessageKit frameWork uses section to seperate the messages
        // Because a message on screen can have multiple pieces.
        messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        messages.count
    }
}
