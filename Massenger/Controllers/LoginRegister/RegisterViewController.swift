//
//  RegisterViewController.swift
//  Massenger
//
//  Created by Rajat verma on 28/09/23.
//

import UIKit

class RegisterViewController: UIViewController {
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .lightGray
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private let emailField: UITextField = {
        let emailField = UITextField()
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no
        emailField.returnKeyType = .continue
        emailField.layer.cornerRadius = 12
        emailField.layer.borderWidth = 1
        emailField.layer.borderColor = UIColor.lightGray.cgColor
        emailField.placeholder = "Enter Email here"
        emailField.leftView = UIView(frame: .init(x: 0, y: 0, width: 5, height: 0))
        emailField.leftViewMode = .always
        emailField.backgroundColor = .white
        return emailField
    }()
    
    private let passwordField: UITextField = {
        let passwordField = UITextField()
        passwordField.autocapitalizationType = .none
        passwordField.autocorrectionType = .no
        passwordField.returnKeyType = .done
        passwordField.layer.cornerRadius = 12
        passwordField.layer.borderWidth = 1
        passwordField.layer.borderColor = UIColor.lightGray.cgColor
        passwordField.placeholder = "Enter Password here"
        passwordField.leftView = UIView(frame: .init(x: 0, y: 0, width: 5, height: 0))
        passwordField.leftViewMode = .always
        passwordField.backgroundColor = .white
        passwordField.isSecureTextEntry = true
        return passwordField
    }()
    
    private let firstNameField: UITextField = {
        let emailField = UITextField()
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no
        emailField.returnKeyType = .continue
        emailField.layer.cornerRadius = 12
        emailField.layer.borderWidth = 1
        emailField.layer.borderColor = UIColor.lightGray.cgColor
        emailField.placeholder = "First Name here"
        emailField.leftView = UIView(frame: .init(x: 0, y: 0, width: 5, height: 0))
        emailField.leftViewMode = .always
        emailField.backgroundColor = .white
        return emailField
    }()
    
    private let lastNameField: UITextField = {
        let emailField = UITextField()
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no
        emailField.returnKeyType = .continue
        emailField.layer.cornerRadius = 12
        emailField.layer.borderWidth = 1
        emailField.layer.borderColor = UIColor.lightGray.cgColor
        emailField.placeholder = "Last Name here"
        emailField.leftView = UIView(frame: .init(x: 0, y: 0, width: 5, height: 0))
        emailField.leftViewMode = .always
        emailField.backgroundColor = .white
        return emailField
    }()
    
    private let loginButton: UIButton = {
        let loginButton = UIButton()
        loginButton.setTitle("Register", for: .normal)
        loginButton.backgroundColor = .systemGreen
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 12
        loginButton.layer.masksToBounds = true ///Cuts the layers that overflows the corner radius
        loginButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return loginButton
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Register"
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        // Do any additional setup after loading the view.
        initAppearance()
        
        emailField.delegate = self
        passwordField.delegate = self
        
        let guesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
        guesture.numberOfTapsRequired = 1
        guesture.numberOfTouchesRequired = 1
        imageView.addGestureRecognizer(guesture)
        loginButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = view.width / 3
        
        imageView.frame = CGRect(x: (view.width - size) / 2, y: 20, width: size, height: size)
        firstNameField.frame = .init(x: 30, y: imageView.bottom + 25, width: scrollView.width - 60, height: 52)
        lastNameField.frame = .init(x: 30, y: firstNameField.bottom + 20, width: scrollView.width - 60, height: 52)
        emailField.frame = CGRect(x: 30, y: lastNameField.bottom + 20, width: scrollView.width - 60, height: 52)
        passwordField.frame = CGRect(x: 30, y: emailField.bottom + 20, width: scrollView.width - 60, height: 52)
        loginButton.frame = CGRect(x: 80, y: passwordField.bottom + 20, width: scrollView.width - 160, height: 52)
    }
    
    private func initAppearance() {
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
    }
    
    @objc
    private func registerButtonTapped() {
        guard let email = emailField.text,
              let password = passwordField.text,
              let firstName = firstNameField.text,
              let lastName = lastNameField.text,
              !firstName.isEmpty,
              !lastName.isEmpty,
              !email.isEmpty,
              !password.isEmpty,
              password.count > 6 else {
            alertUserRegisterAlert()
            return
        }
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        // FIREBASE LOGIN
    }
    
    @objc
    private func didTapChangeProfilePic() {
        print("Prifle pic tapped")
    }
    
    private func alertUserRegisterAlert() {
        let alert = UIAlertController(title: "Whoops", message: "Please enter all the details carefully", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    @objc
    func didTapRegister() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: UITextFieldDelegate
extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailField:
            passwordField.becomeFirstResponder()
        case passwordField:
            registerButtonTapped()
        default:
            return true
        }
        
        return true
    }
}
