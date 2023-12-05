//
//  DatabaseManager.swift
//  Massenger
//
//  Created by Rajat verma on 29/11/23.
//

import Foundation
import FirebaseDatabase

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
            completion(true)
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
