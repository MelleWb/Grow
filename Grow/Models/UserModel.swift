//
//  UserModel.swift
//  Pods
//
//  Created by Swen Rolink on 27/06/2021.
//

import Foundation
import SwiftUI
import FirebaseFirestoreSwift
import Firebase
import Cache


struct User: Codable {
    @DocumentID var id: String?
    var firstName: String?
    var lastName: String?
    var dateOfBirth: Date?
    var gender: Int?
    var coach: String?
    var coachPictureURL: String?
    var userImageURL: String?
    var height: Int?
    var weight: Int?
    var plan: Int?
    var kcal: Int?
    var carbs: Int?
    var protein: Int?
    var fat: Int?
    var fiber: Int?
    var pal: Int?
    var fcmToken: String?
    
    init(id: String? = nil,
         firstName: String? = nil,
         lastName: String? = nil,
         dateOfBirth: Date? = nil,
         gender: Int? = nil,
         coach: String? = nil,
         coachPictureURL: String? = nil,
         userImageURL: String? = nil,
         height: Int? = nil,
         weight: Int? = nil,
         plan: Int? = nil,
         kcal: Int? = nil,
         carbs: Int? = nil,
         protein: Int? = nil,
         fat: Int? = nil,
         fiber: Int? = nil,
         pal: Int? = nil,
         fcmToken: String? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.coach = coach
        self.coachPictureURL = coachPictureURL
        self.userImageURL = userImageURL
        self.height = height
        self.weight = weight
        self.plan = plan
        self.kcal = kcal
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.fiber = fiber
        self.pal = pal
        self.fcmToken = fcmToken
    }
}

struct UserImages {
    var userImage: ImageWrapper?
    var coachImage: ImageWrapper?
    
    init(
        userImage: ImageWrapper? = nil,
        coachImage: ImageWrapper? = nil
    ){
        self.coachImage = coachImage
        self.userImage = userImage
    }
}

class UserDataModel: ObservableObject{
    
    @Published var user = User()
    @Published var userImages = UserImages()
    @Published var errorMessage: String?
    
    func fetchUser(uid: String) {
        
    let settings = FirestoreSettings()
    settings.isPersistenceEnabled = true
    let db = Firestore.firestore()
        
      let docRef = db.collection("users").document(uid)
        
      docRef.getDocument { document, error in
        if (error as NSError?) != nil {
            self.errorMessage = "Error getting document: \(error?.localizedDescription ?? "Unknown error")"
        }
        else {
          if let document = document {
            do {
                self.user = try document.data(as: User.self)!
                
                if self.user.coachPictureURL != nil {
                    
                    let storage = Storage.storage()
                    let imageRef = storage.reference(forURL: self.user.coachPictureURL ?? "gs://")
                    let defaultImage: UIImage = UIImage(named: "errorLoading")!

                    // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
                    imageRef.getData(maxSize: 1 * 4000 * 4000) { data, error in
                        if error != nil {
                            self.userImages.coachImage = ImageWrapper(image: defaultImage)
                      } else {
                            self.userImages.coachImage = ImageWrapper(image: UIImage(data: data!) ?? defaultImage)
                      }
                        
                    }
                }
                if self.user.userImageURL != nil {
                    let storage = Storage.storage()
                    let imageRef = storage.reference(forURL: self.user.userImageURL ?? "gs://")
                    let defaultImage: UIImage = UIImage(named: "errorLoading")!

                    // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
                    imageRef.getData(maxSize: 1 * 4000 * 4000) { data, error in
                        if error != nil {
                            self.userImages.userImage = ImageWrapper(image: defaultImage)
                      } else {
                            self.userImages.userImage = ImageWrapper(image: UIImage(data: data!) ?? defaultImage)
                      }
                        
                    }
                }
            }
            catch {
              print(error)
            }
          }
        }
      }
    }
    
    func updateUser() {
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
      if let id = user.id {
        let docRef = db.collection("users").document(id)
        do {
          try docRef.setData(from: user, merge: true)
        }
        catch {
          print(error)
        }
      }
    }
    
   
}

