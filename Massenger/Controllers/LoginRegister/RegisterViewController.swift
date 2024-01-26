 //
//  RegisterViewController.swift
//  Massenger
//
//  Created by Rajat verma on 28/09/23.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class RegisterViewController: UIViewController {
    
    private let spinner: JGProgressHUD = {
        let spinner = JGProgressHUD()
        spinner.style = .dark
        return spinner
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .lightGray
        imageView.isUserInteractionEnabled = true
        imageView.layer.masksToBounds = true
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
        
        imageView.layer.cornerRadius = imageView.width / 2
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
            alertUserRegisterAlert(message: "Please enter all information to create an account ")
            return
        }
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        spinner.show(in: view)
        
        // FIREBASE LOGIN
        DatabaseManager.shared.userExistsWithEmail(with: email) { [weak self] exists in
            DispatchQueue.main.async {
                self?.spinner.dismiss()
            }
            if !exists {
                FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                    guard error == nil,
                          let result = authResult else {
                        print("Error creating user, error -> \(error?.localizedDescription ?? "")")
                        return
                    }
                    
                    let user = result.user
                    print("created user -> \(user)")
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, email: email)
                    DatabaseManager.shared.inserUser(with: chatUser) { isInserted in
                        if isInserted {
                            // UPLOAD IMAGE
                            guard let image = self?.imageView.image,
                                  let imageData = image.pngData() else {
                                print("self not found")
                                self?.dismiss(animated: true)
                                return
                            }
                            let fileName = chatUser.profilePictureFileName
                            StorageManager.shared.uploadProfilePicture(data: imageData,
                                                                       fileName: fileName) { result in
                                switch result {
                                case .success(let downloadUrl):
                                    print(downloadUrl)
                                    UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                    
                                case .failure(let error):
                                    print("storage manager error -> \(error.localizedDescription)")
                                }
                            }
                            self?.dismiss(animated: true)
                        }
                    }
                }
                return
            }
            self?.alertUserRegisterAlert(message: "Email already exists, please use a different email address")
            // Show user already exists error
        }
    }
    
    @objc
    private func didTapChangeProfilePic() {
        presentPhotoActionSheet()
    }
    
    private func alertUserRegisterAlert(message: String) {
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

// MARK: UIImagePickerControllerDelegate
extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // This delegate provides us the result after user takes a picture from camera/gallery
    private func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile Picture", message: "How would you like to select a picture?", preferredStyle: .actionSheet)
        actionSheet.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        
        actionSheet.addAction(.init(title: "Take a photo", style: .default, handler: { [weak self] _ in
            self?.presentCamera()
        }))
        
        actionSheet.addAction(.init(title: "Choose a photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoPicker()
        }))
        
        present(actionSheet, animated: true)
    }
    
    private func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self // Also inherits UINavigationControllerDelegate
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    private func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self // Also inherits UINavigationControllerDelegate
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let imagePicked = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            imageView.image = imagePicked
        }
        picker.dismiss(animated: true)
    }
}
