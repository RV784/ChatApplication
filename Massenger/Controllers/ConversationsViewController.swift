//
//  ViewController.swift
//  Massenger
//
//  Created by Rajat verma on 28/09/23.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class ConversationsViewController: UIViewController {
    
    private var conversations = [Conversation]()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return table
    }()
    
    private let noConversationLabel: UILabel = {
        let label = UILabel()
        label.text = "No conversations found!"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.textColor = .gray
        label.isHidden = true
        return label
    }()
    
    private let spinner: JGProgressHUD = {
        let spinner = JGProgressHUD()
        spinner.style = .dark
        return spinner
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        view.addSubview(tableView)
        view.addSubview(noConversationLabel)
        setupTableView()
        fetchConversations()
        startListeningForConversation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.title = "Chats"
        validateAuth()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func startListeningForConversation() {
        guard let userEmail = UserDefaults.standard.string(forKey: "email") else {
            return
        }
        print("Starting conversation fetch")
        DatabaseManager.shared.getAllConversations(for: DatabaseManager.safeEmail(email: userEmail)) { [weak self] result in
            switch result {
                
            case .success(let conversations):
                print("successfully got convo models")
                guard !conversations.isEmpty else {
                    return
                }
                self?.conversations = conversations
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print("Failed to get convos \(error.localizedDescription)")
            }
        }
    }
    
    private func validateAuth() {
        // The current user property will set when you log in the user
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let navVC = UINavigationController(rootViewController: vc)
            navVC.modalPresentationStyle = .overFullScreen
            present(navVC, animated: true)
        }
    }
    
    private func fetchConversations() {
        tableView.isHidden = false
    }
    
    @objc
    private func didTapComposeButton() {
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in
            self?.createNewConversation(with: result)
            print(result)
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    private func createNewConversation(with result: [String: String]) {
        guard let name = result["name"],
              let safeEmail = result["safe_email"] else {
            return
        }
        let vc = ChatViewController(with: safeEmail, id: nil)
        vc.isNewConversation = true
        vc.title = name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate
extension ConversationsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as? ConversationTableViewCell {
            cell.configure(model: model)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = conversations[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        120
    }
}
