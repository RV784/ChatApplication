//
//  StorageManager.swift
//  Massenger
//
//  Created by Rajat verma on 04/12/23.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    static let shared = StorageManager()
    private init() {}
    
    private let storage = Storage.storage().reference()
    
    /*
     // images/rajat-verma-email-com_profile_picture.png
     
     */
    
    
    public typealias uploadPictureCompletion = (Result<String, Error>) -> Void
    
    ///Uploads pictures to firebase storage and returns completion with URLString to download
    public func uploadProfilePicture(data: Data,
                                     fileName: String,
                                     completion: @escaping uploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metaData, error in
            guard error == nil else {
                print("failed to upload data to firebase for pictures")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("images/\(fileName)").downloadURL { url, error in
                guard let url = url else {
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download url returned: \(urlString)")
                completion(.success(urlString))
            }
        })
    }
}

public enum StorageErrors: Error {
    case failedToUpload
    case failedToGetDownloadURL
}
