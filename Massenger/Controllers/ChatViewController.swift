//
//  ChatViewController.swift
//  Massenger
//
//  Created by Rajat verma on 02/12/23.
//

import UIKit
import MessageKit
import InputBarAccessoryView

class ChatViewController: MessagesViewController {
    
    public static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    private var messages = [Message]()
    private var selfSender: Sender? {
        guard let userEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(email: userEmail)
        
        return Sender(photoUrl: "",
               senderId: safeEmail,
               displayName: "Me")
    }
    public var isNewConversation = false
    public let otherUserEmail: String
    private let conversationId: String?

    init(with email: String, id: String?) {
        self.otherUserEmail = email
        self.conversationId = id
        super.init(nibName: nil, bundle: nil)
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
//        messages.append(.init(sender: selfSender,
//                              messageId: "1",
//                              sentDate: Date(),
//                              kind: .text("Hello World message"))
//        )
//        
//        messages.append(.init(sender: selfSender,
//                              messageId: "1",
//                              sentDate: Date(),
//                              kind: .text("Lmao this is weird"))
//        )
        messageInputBar.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    private func createMessageId() -> String? {
        // Date, OtherUserEmail, SendEmail, randomInt
        guard let currentUserEmail = UserDefaults.standard.string(forKey: "email") else {
            return nil
        }
        let safeCurrentEmail = DatabaseManager.safeEmail(email: currentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        print("Created message Id: \(dateString)")
        return newIdentifier
    }
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id) { [weak self] result in
            switch result {
                
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadData()
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem()
                    } else {
                        self?.messagesCollectionView.reloadDataAndKeepOffset()
                    }
                }
            case .failure(let error):
                print("Failed to get messages \(error.localizedDescription)")
            }
        }
    }
}

// MARK: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    // Who the current sender is?
    func currentSender() -> MessageKit.SenderType {
        if let selfSender = selfSender {
            return selfSender
        }
        fatalError("SelfSender is nil, email should be cashed")
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

// MARK: InputBarAccessoryViewDelegate
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = selfSender,
              let messageId = createMessageId() else {
            return
        }
        print("Sending Message: \(text)")
        let message = Message(sender: selfSender,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .text(text))
        // Send Message
        if isNewConversation {
            // create convo in DB
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, 
                                                         name: self.title ?? "User ",
                                                         firstMessage: message) { [weak self] success in
                if success {
                    print("Message send")
                    self?.isNewConversation = false
                } else {
                    print("Failed to send")
                }
            }
        } else {
            // Append to existing Convo data
            guard let conversationId = self.conversationId,
                  let name = self.title else { return }
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, name: name, newMessage: message) { success in
                if success {
                    print("message send")
                } else {
                    print("failed to sent")
                }
            }
        }
    }
}
