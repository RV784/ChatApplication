//
//  DatabaseManager.swift
//  Massenger
//
//  Created by Rajat verma on 29/11/23.
//

import Foundation
import FirebaseDatabase
import MessageKit

final class DatabaseManager {
    static let shared = DatabaseManager()
    private init() {}
    
    private var database = Database.database().reference()
    
    private func test() {
        // Our database basically is a Json
        // Here .chile("foo") means a key is there named foo
        // Passing nil as the key setValue will delete the key itself
        database.child("foo").setValue(["something": true])
    }
    
    static func safeEmail(email: String) -> String {
        let safeEmail = email.replacingOccurrences(of: ".", with: "-").replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

// MARK: Account Management
extension DatabaseManager {
    /// If this returns true, user with same email already exists so cannot use it
    public func userExistsWithEmail(with email: String, completion: @escaping (Bool) -> Void) {
        // That snapshot.childCount will be 0 if the user already does not exists
        
        let safeEmail = email.replacingOccurrences(of: ".", with: "-").replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshop in
            guard snapshop.childrenCount != 0 else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// Inserts a user to firebase realtime database
    public func inserUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        database.child("\(user.safeEmail)").setValue([
            "firstName": user.firstName,
            "lastName": user.lastName
        ]) { error, _ in
            guard error == nil else {
                print("Failed to write to DataBase")
                completion(false)
                return
            }
            
            /* Users Array
             
            users =>  [
                [
                    "name": wekjn,
                    "safe_email": wkeubfcjn
                ],
                [
                 "name": wekjn,
                 "safe_email": wkeubfcjn
                ],
             ]
             */
            self.database.child("users").observeSingleEvent(of: .value) { snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    // Append to user dictionary
                    let newElemtent = [
                        "name": "\(user.firstName) \(user.lastName)",
                        "safe_email": user.safeEmail
                    ]
                    usersCollection.append(newElemtent)
                    self.database.child("users").setValue(usersCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    }
                } else {
                    // Create a user dictionary
                    let newCollection: [[String: String]] = [
                        [
                            "name": "\(user.firstName) \(user.lastName)",
                            "safe_email": user.safeEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    }
                }
            }
        }
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}

// MARK: Sending Messages/Conversations
extension DatabaseManager {
    // DB Schema
    /*
     "yuioiuyu": {
        "messages": [
            {
                "id": String
                "type": Photo, Video, Text
                "content": String,
                "date": Date,
                "senderEmail": String
                "isRead": Bool
            }
        ]
     }
     
     
    Conversation => [
        [
            "conversation_id": "yuioiuyu"
            "otherUserEmail":
            "latest_message" => [
                            "date":
                            "latestMessage":
                            "is_read":
                        ]
        ]
     
     ]
     */
    
    
    /// Creates a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.string(forKey: "email"),
              let currentName = UserDefaults.standard.string(forKey: "name") else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(email: currentEmail)
        let ref = database.child(safeEmail)
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("User not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationID = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String: Any] = [
                "id": conversationID,
                "otherUserEmail": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "is_read": false,
                    "message": message
                ]
            ]
            
            let recipeintNewConversation: [String: Any] = [
                "id": conversationID,
                "otherUserEmail": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "is_read": false,
                    "message": message
                ]
            ]
            
            // Update recipeint conversation entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    // Append
                    conversations.append(recipeintNewConversation)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                } else {
                    // The recipent user does not have conversations, create it for them
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipeintNewConversation])
                }
            }
            
            // Update current user's conversation entry
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // Conversation exists for a current user, you should append
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationID,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                }
            } else {
                // You should create a new conversation
                userNode["conversations"] = [
                    newConversationData
                ]
                ref.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationID,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                }
            }
        }
    }
    
    private func finishCreatingConversation(name: String,  conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
//        {
//            "id": String
//            "type": Photo, Video, Text
//            "content": String,
//            "date": Date,
//            "senderEmail": String
//            "isRead": Bool
//        }
        
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        guard let currentUserEmail = UserDefaults.standard.string(forKey: "email") else {
            completion(false)
            return
        }
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "senderEmail": DatabaseManager.safeEmail(email: currentUserEmail),
            "isRead": false,
            "name": name
        ]
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        print("Adding convo: \(conversationID)")
        
        database.child(conversationID).setValue(value) { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// Fetches and returns all conversations for the user with passed email
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void)  {
        database.child("\(email)/conversations").observe(.value) { snapShot in
            guard let value = snapShot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let conversationsArray: [Conversation] = value.compactMap { dict in
                guard let conversationID = dict["id"] as? String,
                      let name = dict["name"] as? String,
                      let otherUserEmail = dict["otherUserEmail"] as? String,
                      let latestMessage = dict["latest_message"] as? [String: Any],
                      let isRead = latestMessage["is_read"] as? Bool,
                      let message = latestMessage["message"] as? String,
                      let date = latestMessage["date"] as? String else {
                        return nil
                    }
                
                return Conversation(id: conversationID,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: LatestMessage(date: date,
                                                                 text: message,
                                                                 isRead: isRead))
            }
            completion(.success(conversationsArray))
        }
    }
    
    /// Get all message for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(id)/messages").observe(.value) { snapShot in
            guard let value = snapShot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let messages: [Message] = value.compactMap { dict in
                guard let name = dict["name"] as? String,
                      let content = dict["content"] as? String,
                      let messageId = dict["id"] as? String,
                      let _ = dict["isRead"] as? Bool,
                      let dateString = dict["date"] as? String,
                      let senderEmail = dict["senderEmail"] as? String,
                      let type = dict["type"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else {
                    return nil
                }
                
                var kind: MessageKind?
                if type == "photo" {
                    guard let imageURL = URL(string: content),
                          let placeholderImage = UIImage(systemName: "plus") else {
                        return nil
                    }
                    let media = Media(url: imageURL,
                                      image: nil,
                                      placeholderImage: placeholderImage,
                                      size: .init(width: 250, height: 250))
                    kind = .photo(media)
                } else {
                    kind = .text(content)
                }
                
                guard let finalKind = kind else {
                    return nil
                }
                
                let sender = Sender.init(photoUrl: "",
                                         senderId: senderEmail,
                                         displayName: name)
                
                return .init(sender: sender,
                             messageId: messageId,
                             sentDate: date,
                             kind: finalKind)
            }
            completion(.success(messages))
        }
    }
    
    /// Send a message with target conversation and message
    public func sendMessage(to conversationId: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void) {
        // Step - 1 Add new messages to Messages, COMPLETED
        
        // Step - 2 Update sender's latest message to this conversation
        
        // Step - 3 update recepeint's latest message to this conversation
        
        
        guard let myEmail = UserDefaults.standard.string(forKey: "email") else {
            completion(false)
            return
        }
        let currentSafeEmail = DatabaseManager.safeEmail(email: myEmail)
        
//        Step - 1
        database.child("\(conversationId)/messages").observeSingleEvent(of: .value) { [weak self] snapshot  in
            guard var currentMessage = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            var message = ""
            
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                message = mediaItem.url?.absoluteString ?? ""
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            guard let currentUserEmail = UserDefaults.standard.string(forKey: "email") else {
                completion(false)
                return
            }
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "senderEmail": DatabaseManager.safeEmail(email: currentUserEmail),
                "isRead": false,
                "name": name
            ]
            
            currentMessage.append(newMessageEntry)
            self?.database.child("\(conversationId)/messages").setValue(currentMessage) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                self?.database.child("\(currentSafeEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                    guard var currentUserConversations = snapshot.value as? [[String: Any]] else {
                        completion(false)
                        return
                    }
                    
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]
                    
                    var targetConversation: [String: Any]?
                    
                    var position = 0
                    
                    for conversation in currentUserConversations {
                        if let currentId = conversation["id"] as? String,
                           currentId == conversationId {
                            targetConversation = conversation
                            break
                        }
                        position+=1
                    }
                    
                    targetConversation?["latest_message"] = updatedValue
                    guard let targetConversation = targetConversation else {
                        completion(false)
                        return
                    }
                    currentUserConversations[position] = targetConversation
                    self?.database.child("\(currentSafeEmail)/conversations").setValue(currentUserConversations) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        // Update Latest message for recepint User
                        self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                            guard var otherUserConversations = snapshot.value as? [[String: Any]] else {
                                completion(false)
                                return
                            }
                            
                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": message
                            ]
                            
                            var targetConversation: [String: Any]?
                            
                            var position = 0
                            
                            for conversation in otherUserConversations {
                                if let currentId = conversation["id"] as? String,
                                   currentId == conversationId {
                                    targetConversation = conversation
                                    break
                                }
                                position+=1
                            }
                            
                            targetConversation?["latest_message"] = updatedValue
                            guard let targetConversation = targetConversation else {
                                completion(false)
                                return
                            }
                            otherUserConversations[position] = targetConversation
                            self?.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversations) { error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: GETTING FirstName and LastName
extension DatabaseManager {
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        self.database.child(path).observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}

struct ChatAppUser {
    let firstName: String
    let lastName: String
    let email: String
    
    var safeEmail: String {
        let safeEmail = email.replacingOccurrences(of: ".", with: "-").replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
}


public enum DatabaseError: Error {
    case failedToFetch
}
