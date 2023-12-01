//
//  LoginViewController.swift
//  Massenger
//
//  Created by Rajat verma on 28/09/23.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

class LoginViewController: UIViewController {
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "massenger_image")
        imageView.contentMode = .scaleAspectFit
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
        passwordField.placeholder = "Enter your password"
        passwordField.leftView = UIView(frame: .init(x: 0, y: 0, width: 5, height: 0))
        passwordField.leftViewMode = .always
        passwordField.backgroundColor = .white
        passwordField.isSecureTextEntry = true
        return passwordField
    }()
    
    private let loginButton: UIButton = {
        let loginButton = UIButton()
        loginButton.setTitle("Log in", for: .normal)
        loginButton.backgroundColor = .link
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 12
        loginButton.layer.masksToBounds = true ///Cuts the layers that overflows the corner radius
        loginButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return loginButton
    }()
    
    private let googleSignInButton: GIDSignInButton = {
        let button = GIDSignInButton()
        button.backgroundColor = .link
        button.layer.cornerRadius = 12
        button.style = .wide
        button.colorScheme = .dark
        button.inputView?.backgroundColor = .purple
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log In"
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        // Do any additional setup after loading the view.
        initAppearance()
        
        emailField.delegate = self
        passwordField.delegate = self
        googleSignInButton.addTarget(self, action: #selector(googleSignInClicked), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = view.width / 3
        
        imageView.frame = CGRect(x: (view.width - size) / 2, y: 20, width: size, height: size)
        emailField.frame = CGRect(x: 30, y: imageView.bottom + 25, width: scrollView.width - 60, height: 52)
        passwordField.frame = CGRect(x: 30, y: emailField.bottom + 20, width: scrollView.width - 60, height: 52)
        loginButton.frame = CGRect(x: 80, y: passwordField.bottom + 20, width: scrollView.width - 160, height: 52)
        googleSignInButton.frame = CGRect(x: 80, y: loginButton.bottom + 20, width: scrollView.width - 160, height: 52)
    }
    
    private func initAppearance() {
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(googleSignInButton)
    }
    
    @objc
    private func loginButtonTapped() {
        guard let email = emailField.text,
              let password = passwordField.text,
              !email.isEmpty,
              !password.isEmpty,
              password.count > 6 else {
            alertUserLoginError(message: "Please enter all the details carefully")
            return
        }
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        // FIREBASE REGISTER
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard error == nil,
                  let result = authResult else {
                print("Error logging in user, error -> \(error?.localizedDescription ?? "")")
                self?.alertUserLoginError(message: "User with this email-Id does not exists")
                return
            }
            
            let user = result.user
            print("verified user user -> \(user)")
            self?.dismiss(animated: true)
        }
    }
    
    private func alertUserLoginError(message: String) {
        let alert = UIAlertController(title: "Whoops", message: message, preferredStyle: .alert)
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
    
    @objc
    func googleSignInClicked() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [unowned self] result, error in
            guard error == nil else {
                self.alertUserLoginError(message: "Something went wrong, please try again later")
                print(error?.localizedDescription)
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString
            else {
                self.alertUserLoginError(message: "Something went wrong, please try again later")
                print(error?.localizedDescription)
                return
            }
            
            self.registerViaGoogle(user: user, idToken: idToken)
        }
    }
    
    // Registraiton via google is done on loginScreen
    private func registerViaGoogle(user: GIDGoogleUser, idToken: String) {
        guard let email = user.profile?.email,
           let firstName = user.profile?.givenName,
           let lastName = user.profile?.familyName else {
            self.alertUserLoginError(message: "Something went wrong, please try again later")
            return
        }
        
        DatabaseManager.shared.userExistsWithEmail(with: email ?? "") { doesExists in
            if !doesExists {
                DatabaseManager.shared.inserUser(with: .init(firstName: firstName, lastName: lastName, email: email))
            }
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: user.accessToken.tokenString)
        
        FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            guard authResult != nil,
                  error == nil else {
                self?.alertUserLoginError(message: "Something went wrong, please try again later")
                return
            }
            print("Google sign in successful")
            self?.dismiss(animated: true)
        }
    }
}

// MARK: UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailField:
            passwordField.becomeFirstResponder()
        case passwordField:
            loginButtonTapped()
        default:
            return true
        }
        
        return true
    }
}
