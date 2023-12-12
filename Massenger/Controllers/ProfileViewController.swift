//
//  ProfileViewController.swift
//  Massenger
//
//  Created by Rajat verma on 28/09/23.
//

import UIKit
import FirebaseAuth
import GoogleSignIn

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var profileTableView: UITableView! {
        didSet {
            profileTableView.delegate = self
            profileTableView.dataSource = self
            profileTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        }
    }
    
    let data = ["Log out"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.title = "Settings"
        profileTableView.tableHeaderView = createTableHeader()
        // Do any additional setup after loading the view.
    }
    
    func createTableHeader() -> UIView? {
        guard let email = UserDefaults.standard.object(forKey: "email") as? String else {
            return nil
        }
        let fileName = DatabaseManager.safeEmail(email: email) + "_profile_picture.png"
        let path = "images/" + fileName
        let headerView = UIView(frame: .init(x: 0, y: 0, width: self.view.width, height: 300))
        headerView.backgroundColor = .link
        let imageView = UIImageView(frame: .init(x: (headerView.width - 150)/2, y: 75, width: 150, height: 150))
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width/2
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadUrl(for: path) { [weak self] result in
            switch result {
            case .success(let url):
                self?.downloadImage(imageView: imageView, url: url)
            case .failure(let error):
                print("Failed to get download url: \(error.localizedDescription)")
            }
        }
        
        return headerView
    }
    
    func downloadImage(imageView: UIImageView, url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data,
                  error == nil else {
                return
            }
            
            DispatchQueue.main.async {
                imageView.image = UIImage(data: data)
            }
        }.resume()
    }
    
    private func logOut() {
        do {
            try FirebaseAuth.Auth.auth().signOut()
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        } catch {
            print("Failed to log out")
        }
    }
}

// MARK:  UITableViewDelegate, UITableViewDataSource
extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = data[indexPath.row]
        content.textProperties.alignment = .center
        content.textProperties.color = .red
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        profileTableView.deselectRow(at: indexPath, animated: true)
        
        let alert = UIAlertController(title: "Massenger", message: "Do you want to logout", preferredStyle: .actionSheet)
        let okAction = UIAlertAction(title: "YES", style: .destructive) { [weak self] _ in
            self?.logOut()
        }
        let noAction = UIAlertAction(title: "NO", style: .default)
        alert.addAction(okAction)
        alert.addAction(noAction)
        present(alert, animated: true)
    }
}
