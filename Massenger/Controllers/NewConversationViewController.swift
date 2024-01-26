//
//  NewConversationViewController.swift
//  Massenger
//
//  Created by Rajat verma on 28/09/23.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    private var users: [[String: String]] = []
    private var results: [[String: String]] = []
    private var hasFetched = false
    public var completion: (([String: String]) -> Void)?
    
    private var searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "Search for users"
        return bar
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.addSubview(noResultsLabel)
        view.addSubview(tableView)
        view.backgroundColor = .white
        searchBar.delegate = self
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", 
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultsLabel.frame = .init(x: view.width/4, y: (view.height - 200)/2, width: view.width/2, height: 200)
    }
    
    @objc
    private func dismissSelf() {
        dismiss(animated: true)
    }
    
    private func searchUsers(userQuery: String) {
        spinner.show(in: view)
        results.removeAll()
        // Check if array has query results, if Yes then filter...if not then fetch and filter.
        if hasFetched {
            // if Yes then filter
            spinner.dismiss()
            filterUsers(with: userQuery)
            
        } else {
            DatabaseManager.shared.getAllUsers { [weak self] result in
                self?.spinner.dismiss()
                switch result {
                case .success(let users):
                    self?.hasFetched = true
                    self?.users = users
                    self?.filterUsers(with: userQuery)
                case .failure(_):
                    print("Failed to fetch users")
                }
            }
        }
    }
    
    private func filterUsers(with text: String) {
        guard hasFetched else { return }
        var results = users.filter { 
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(text.lowercased())
        }
        
        self.results = results
        updateUI()
    }
    
    private func updateUI() {
        if results.isEmpty {
            noResultsLabel.isHidden = false
            tableView.isHidden = true
        } else {
            noResultsLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
}

// MARK: UISearchBarDelegate
extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text,
              !text.isEmpty,
              !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            print("Nothing is written in the search field")
            return
        }
        searchBar.resignFirstResponder()
        searchUsers(userQuery: text)
    }
}

// MARK: UITableViewDelegate, UITableViewDataSource
extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = results[indexPath.row]["name"]
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Start conversation
        let targetUserData = results[indexPath.row]
        self.dismiss(animated: true) { [weak self] in
            self?.completion?(targetUserData)
        }
    }
}
