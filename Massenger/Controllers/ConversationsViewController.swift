//
//  ViewController.swift
//  Massenger
//
//  Created by Rajat verma on 28/09/23.
//

import UIKit

class ConversationsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .green
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let isLoggedIn = UserDefaults.standard.bool(forKey: "logged_In")
        
        if !isLoggedIn {
            let vc = LoginViewController()
            let navVC = UINavigationController(rootViewController: vc)
            navVC.modalPresentationStyle = .overFullScreen
            present(navVC, animated: true)
        }
    }
}

