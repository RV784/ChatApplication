//
//  ChatViewController.swift
//  Massenger
//
//  Created by Rajat verma on 02/12/23.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit

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
        setupInputButton()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
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
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(.init(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach media",
                                            message: "What would you like to attatch?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { [weak self] _ in
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
            
        }))
        
        present(actionSheet, animated: true)
    }
    
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach photo",
                                            message: "Where would you like to attatch a photo from?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
            
        }))
        
        present(actionSheet, animated: true)
    }
    
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach video",
                                            message: "Where would you like to attatch a video from?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
            
        }))
        
        present(actionSheet, animated: true)
    }
}

// MARK: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, MessageCellDelegate {
    
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
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
            
        case .photo(let media):
            guard let imageURL = media.url else {
                return
            }
            imageView.sd_setImage(with: imageURL)
        default:
            break
        }
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let message = messages[indexPath.section]
        
        switch message.kind {
            
        case .photo(let media):
            guard let imageURL = media.url else {
                return
            }
            let vc = PhotoViewerViewController(with: imageURL)
            self.navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else {
                return
            }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            vc.player?.play()
            present(vc, animated: true)
        default:
            break
        }
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

// MARK: UIImagePickerControllerDelegate
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let conversationId = conversationId,
              let selfSender = selfSender,
              let messageId = createMessageId() else {
            picker.dismiss(animated: true)
            return
        }
        
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
           let imageData = image.pngData() {
            // For a photo
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            
            // Upload the image to firebase
            StorageManager.shared.uploadMessagePhoto(data: imageData, fileName: fileName) { [weak self] result in
                picker.dismiss(animated: true)
                switch result {
                    
                case .success(let imageUrlString):
                    // Ready to send a message in chat with photo
                    print("imageURL: \(imageUrlString)")
                    
                    guard let url = URL(string: imageUrlString),
                          let placeHolder = UIImage(systemName: "plus") else {
                        print("Failed photo image")
                        return
                    }
                    
                    let mediaItem = Media(
                        url: url,
                        image: nil,
                        placeholderImage: placeHolder,
                        size: .zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .photo(mediaItem))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId,
                                                       otherUserEmail: self?.otherUserEmail ?? "",
                                                       name: self?.title ?? "",
                                                       newMessage: message) { success in
                        if success {
                            print("successfully send photo message")
                            
                        } else {
                            print("Failed to send photo message")
                        }
                    }
                case .failure(let error):
                    print("Message upload photo failed: \(error.localizedDescription)")
                }
            }
            // Then send the message in chat
        } else if let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            // Upload Video case
            let fileName = "video_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            
            // Upload the image to firebase
            StorageManager.shared.uploadMessageVideo(fileURL: videoUrl, fileName: fileName) { [weak self] result in
                picker.dismiss(animated: true)
                switch result {
                    
                case .success(let videoUrlString):
                    // Ready to send a message in chat with photo
                    print("videoURL: \(videoUrlString)")
                    
                    guard let url = URL(string: videoUrlString),
                          let placeHolder = UIImage(systemName: "plus") else {
                        print("Failed video")
                        return
                    }
                    
                    let mediaItem = Media(
                        url: url,
                        image: nil,
                        placeholderImage: placeHolder,
                        size: .zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .video(mediaItem))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId,
                                                       otherUserEmail: self?.otherUserEmail ?? "",
                                                       name: self?.title ?? "",
                                                       newMessage: message) { success in
                        if success {
                            print("successfully send video message")
                            
                        } else {
                            print("Failed to send video message")
                        }
                    }
                case .failure(let error):
                    print("Message upload video failed: \(error.localizedDescription)")
                }
            }
            
        }
    }
}
