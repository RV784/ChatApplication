//
//  ConversationTableViewCell.swift
//  Massenger
//
//  Created by Rajat verma on 28/12/23.
//

import UIKit
import SDWebImage

class ConversationTableViewCell: UITableViewCell {
    static let identifier = "ConversationTableViewCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 50
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let userNameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.font = .systemFont(ofSize: 21, weight: .semibold)
        return nameLabel
    }()
    
    private let userMessageLabel: UILabel = {
        let messageLabel = UILabel()
        messageLabel.font = .systemFont(ofSize: 19, weight: .regular)
        messageLabel.numberOfLines = 0
        return messageLabel
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(userMessageLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = .init(x: 10, y: 10, width: 100, height: 100)
        userNameLabel.frame = .init(x: userImageView.right + 10, y: 10, width: contentView.width - 20 - userImageView.width, height: (contentView.height - 20)/2)
        userMessageLabel.frame = .init(x: userImageView.right + 10, y: userNameLabel.bottom + 10, width: contentView.width - 20 - userImageView.width, height: (contentView.height - 20)/2)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(model: Conversation) {
        self.userMessageLabel.text = model.latestMessage.text
        self.userNameLabel.text = model.name
        
        let path = "images/\(model.otherUserEmail)_profile_picture.png"
        StorageManager.shared.downloadUrl(for: path) { [weak self] result in
            switch result {
                
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url)
                }
            case .failure(let error):
                print("Failed to get imageURL \(error.localizedDescription)")
            }
        }
    }
}
