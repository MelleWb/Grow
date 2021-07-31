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
    var schema: String?
    var weekPlan: [DayPlan]?
    var workoutOfTheDay: UUID?
    
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
         fcmToken: String? = nil,
         schema: String? = nil,
         weekPlan: [DayPlan]? = [DayPlan()],
         workoutOfTheDay:UUID? = nil
    ){
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
        self.schema = schema
        self.weekPlan = weekPlan
        self.workoutOfTheDay = workoutOfTheDay
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

struct DayPlan: Codable, Identifiable, Hashable {
    var id = UUID()
    var trainingType: String?
    var routine: UUID?
    var isTrainingDay: Bool?
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
                
                //Fetch User and Coach Image
                self.fetchUserAndCoachImage()
                
                //Fetch weekplan
                self.getWeekSchema()
                
                //Determine workout of the day
                self.determineWorkoutOfTheDay()
                
            }
            catch {
              print(error)
            }
          }
        }
      }
    }

    func fetchUserAndCoachImage(){
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
    
    func getWeekSchema(){
        
        if user.weekPlan == nil{
            //If nil, create a weekplan
            if user.schema != nil {
                //If trainingSchema is not nil, get it and work with it
                var trainingSchema: Schema = Schema()
                let settings = FirestoreSettings()
                settings.isPersistenceEnabled = true
                let db = Firestore.firestore()
                
                let docRef = db.collection("schemas").document(user.schema!)
                  
                docRef.getDocument { document, error in
                  if (error as NSError?) != nil {
                      print("Error getting document: \(error?.localizedDescription ?? "Unknown error")")
                  }
                  else {
                    if let document = document {
                      do {
                        trainingSchema = try document.data(as: Schema.self)!
                        let routineAmount:Int = trainingSchema.routines.count - 1
                        print(routineAmount)
                        let weekDays: [String] = ["Maandag", "Dinsdag", "Woensdag", "Donderdag", "Vrijdag", "Zaterdag", "Zondag"]
                        
                        weekDays.enumerated().forEach( { (index,day) in
                            var daySchema = DayPlan()
                            if index > routineAmount{
                                daySchema.isTrainingDay = false
                            }
                            else {
                                daySchema.isTrainingDay = true
                                daySchema.trainingType = trainingSchema.routines[index].type
                                daySchema.routine = trainingSchema.routines[index].id
                            }
                            
                            if self.user.weekPlan == nil{
                                self.user.weekPlan = [daySchema]
                            }
                            else {
                                self.user.weekPlan?.append(daySchema)
                            }
                        })
                      }
                      catch {
                        print(error)
                      }
                    }
                  }
                }
            }
        }
    }
    
    func getDayForWeekPlan() -> Int{
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())
        let dayOfWeekString:String = Calendar.current.weekdaySymbols[dayOfWeek-1]
        
        if dayOfWeekString == "Sunday"{
            return 6
        }
        else {
            return dayOfWeek - 2
        }
        
    }
    
    func determineWorkoutOfTheDay() {
        let dayOfWeek: Int = self.getDayForWeekPlan()
        if self.user.weekPlan![dayOfWeek].isTrainingDay!{
            self.user.workoutOfTheDay = self.user.weekPlan?[dayOfWeek].routine
        }
        else{
            self.user.workoutOfTheDay = nil
        }
    }
    
    func getTodaysRoutine() -> UUID{
        let dayOfWeek: Int = self.getDayForWeekPlan()
        return self.user.weekPlan![dayOfWeek].routine!
    }
    
    func updateUserModel(for key: String, to value: Any){
        if key == "firstName"{
            self.user.firstName = value as? String
        }
        if key == "lastName"{
            self.user.lastName = value as? String
        }
        if key == "gender"{
            self.user.lastName = value as? String
        }
        if key == "dateOfBirth"{
            self.user.dateOfBirth = value as? Date
        }
        if key == "weight"{
            self.user.weight = value as? Int
        }
        if key == "height"{
            self.user.height = value as? Int
        }
        if key == "plan"{
            self.user.plan = value as? Int
        }
        if key == "pal"{
            self.user.pal = value as? Int
        }
        if key == "workoutSchema"{
            self.user.schema = value as? String
        }
    }
    
    func uploadPicture(for image: UIImage){
        let storageRef = Storage.storage().reference().child(self.user.id ?? "UserPicture \((UUID()))")
        
        let compressedImage: UIImage = resizeImage(image:image, targetSize: CGSize(width: 500, height: 500))!
        
        if let uploadData = compressedImage.pngData(){
            storageRef.putData(uploadData, metadata: nil, completion: {(metadata, error)in
                if error != nil {
                    print("error")
                    return
                }
                else {
                    storageRef.downloadURL(completion: {(url, error) in
                        print("Image URL: \((url?.absoluteString)!)")
                        self.user.userImageURL = url?.absoluteString
                    })
                }
            })
        }
    }
        
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(origin: .zero, size: newSize)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
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

