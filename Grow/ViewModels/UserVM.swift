//
//  UserModel.swift
//  Pods
//
//  Created by Swen Rolink on 27/06/2021.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
import SwiftUI

class UserDataModel: ObservableObject{
    
    @Published var user = User()
    @Published var userImages = UserImages()
    @Published var isNewMeasurementDay: Bool = false
    @Published var measurement = BodyMeasurement()
    @Published var measurements = [BodyMeasurement()]
    @Published var errorMessage: String?
    @Published var queryRunning: Bool = true
    @Published var workoutDonePercentage: Float = 0.0
    @Published var currentDate: Date = Date()
    var measurementListener: ListenerRegistration? = nil
    
    @ObservedObject var storeManager = StoreManager()
    
    private enum UserError: Error {
        case NoUserID
        case NoSchemaFound
        case UnableToDetermineAge
        case PalValueNil
        case IssueWithCalories
    }
    
    init(){
        storeManager.startObserving()
        storeManager.getProducts()
        
        if Auth.auth().currentUser?.uid != nil{
            self.fetchUser(uid: Auth.auth().currentUser!.uid){
                //Just wait until it's done
            }
        }
    }

    
    func fetchUser(uid: String, finished: () -> Void){
        
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
                
                //Check membership
                self.checkMemberShip()
                
                //Fetch weekplan and determine the weekstats
                self.getWeekSchema(){
                    //Just wait until it's done
                }

                self.determineWorkoutOfTheDay()
                
                //Get training statistics
                self.getTrainingStatsForCurrentWeek()
                
                //Get measurements
                self.getBodyMeasurements()
                
                //Update query Running
                self.queryRunning = false
                
            }
            catch {
              print(error)
            }
          }
        }
      }
    }
    
    func isSameDay(date1: Date, date2: Date) -> Bool {
        let diff = Calendar.current.dateComponents([.day], from: date1, to: date2)
        if diff.day == 0 {
            return true
        } else {
            return false
        }
    }
    
    func checkMemberShip() {
        for date in storeManager.transactionDates {
            print(date)
        }
        
        if self.user.membership != nil {
            if self.user.membership!.endDate! <= Date () {
                for date in storeManager.transactionDates {
                    self.user.membership!.endDate = date
                    self.updateUser()
                }
            }
        }
        storeManager.stopObserving()
    }
    
    func getWeekSchema(finished: () -> Void){
        
        if user.weekPlan == nil{
            //If nil, create a weekplan
            if let schema = user.schema {
                //If trainingSchema is not nil, get it and work with it
                var trainingSchema: Schema = Schema()
                let settings = FirestoreSettings()
                settings.isPersistenceEnabled = true
                let db = Firestore.firestore()
                
                let docRef = db.collection("schemas").document(schema)
                  
                docRef.getDocument { document, error in
                  if (error as NSError?) != nil {
                      print("Error getting document: \(error?.localizedDescription ?? "Unknown error")")
                  }
                  else {
                    if let document = document {
                      do {
                        trainingSchema = try document.data(as: Schema.self)!
                        let routineAmount:Int = trainingSchema.routines.count - 1

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
                finished()
            }
        }
    }
    
    func getDayForWeekPlan() -> Int{
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())
        
        if dayOfWeek == 1{
            return 6
        }
        else {
            return dayOfWeek - 2
        }
        
    }
    
    func getAmountOfWorkOuts() -> Int {
        var count: Int = 0
        
        if user.weekPlan != nil{
            for plan in user.weekPlan! {
                if plan.isTrainingDay ?? false {
                    count += 1
                }
            }
        }
        return count
    }
    
    func determineWorkoutOfTheDay() {
        let dayOfWeek: Int = self.getDayForWeekPlan()
        
        if self.user.weekPlan == nil {
            // don't determine the workout of today
            print("Weekplan is nil, don't determine the WoD")
        } else {
            if self.user.weekPlan![dayOfWeek].isTrainingDay != nil{
                if self.user.weekPlan![dayOfWeek].isTrainingDay! {
                    self.user.workoutOfTheDay = self.user.weekPlan?[dayOfWeek].routine
                }
                else{
                    self.user.workoutOfTheDay = nil
                }
            }
            else{
                self.user.workoutOfTheDay = nil
            }
        }
    }
    
    func getTodaysRoutine() -> UUID{
        let dayOfWeek: Int = self.getDayForWeekPlan()
        return self.user.weekPlan![dayOfWeek].routine!
    }
    
    func getTrainingStatsForCurrentWeek(){
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        let dateArray: [Date] = DateHelper.calcWeekDates()
        
        db.collection("users").document(user.id!).collection("trainingStatistics")
            .whereField("trainingDate", isGreaterThanOrEqualTo: dateArray[0])
            .whereField("trainingDate", isLessThanOrEqualTo: dateArray[1]).addSnapshotListener { (querySnapshot, err) in
                
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    var workoutsDone: Int = 0
                    for _ in querySnapshot!.documents {
                        workoutsDone += 1
                    }
                    
                    //calculate the progress
                    self.workoutDonePercentage = Float(workoutsDone)/Float(self.getAmountOfWorkOuts())
                }
            }
    }
    
    enum UserKey : String {
        case FirstName, LastName, Gender, DateOfBirth, Weight, Height, Plan, NmbrOfTrainings, Pal, ExtraTrainingCalories, WorkoutSchema
    }
    
    func updateUserElements(for key: UserKey, to value: Any) throws {
        switch key {
        case .FirstName:
            self.user.firstName = value as? String
        case .LastName:
            self.user.lastName = value as? String
        case .Gender:
            self.user.gender = value as? Int
        case .DateOfBirth:
            self.user.dateOfBirth = value as? Date
        case .Weight:
            self.user.weight = value as? Int
        case .Height:
            self.user.height = value as? Int
        case .Plan:
            self.user.plan = value as? Int
        case .NmbrOfTrainings:
            self.user.nmbrOfTrainings = value as? Int
        case .Pal:
            self.user.pal = value as? Int
        case .ExtraTrainingCalories:
            self.user.extraCaloriePercentage = value as? Int
        case .WorkoutSchema:
            
            self.user.schema = value as? String
            self.user.weekPlan = nil
            
            //Recreate week schema
            self.getWeekSchema(){
                self.determineWorkoutOfTheDay()
            }
        }
        if key == .ExtraTrainingCalories {
            self.setSportMacros()
        } else {
            do{
                try self.calcKcal()
            }
            catch {
                throw error
            }
        }
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
            self.user.weekPlan = nil
            
            //Recreate week schema
            self.getWeekSchema(){
                self.determineWorkoutOfTheDay()
            }
        }
        do{
            try self.calcKcal()
        }
        catch {
            print("Oops")
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
    
    func saveBodyMeasurement(){
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        let measureRef = db.collection("users").document(Auth.auth().currentUser!.uid).collection("bodyMeasurements").document()
    
            do {
                try measureRef.setData(from: measurement, merge: true)
            }
            catch {
            }
    }
    
    func getBodyMeasurements(){
        
        var docCount:Int = 0
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        let docRef = db.collection("users").document(Auth.auth().currentUser!.uid).collection("bodyMeasurements").order(by: "date", descending: true)
        
        self.measurementListener = docRef.addSnapshotListener { (querySnapshot, error) in
            
                    guard let documents = querySnapshot?.documents else {
                            print("No documents")
                        return
                    }
            
            self.measurements = documents.map { (querySnapshot) -> BodyMeasurement in
                
                let result = Result {
                    try querySnapshot.data(as: BodyMeasurement.self)
                }
                switch result {
                case .success(let measurement):
                    if let measurement = measurement {
                        if docCount == 0 {
                            let calendar = Calendar.current
                            let startOfNow = calendar.startOfDay(for: Date())
                            let startOfTimeStamp = calendar.startOfDay(for: measurement.date)
                                   let components = calendar.dateComponents([.weekOfMonth], from: startOfTimeStamp, to: startOfNow)
                                   let week = components.weekOfMonth!
                            if week >= 3 {
                                self.isNewMeasurementDay = true
                            }
                        }
                        docCount += 1
                        return measurement
                    }
                    else {
                        print ("Document does not exists")
                    }
                case .failure:
                    print("error decoding schema...")
                }
                return BodyMeasurement()
            }
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
            
            //Immediately fetch new data
            self.fetchUser(uid: user.id!){
                //Just wait until it's done
            }
        }
        catch {
          print(error)
        }
      }
    }
    
    func determinePalValue(pal: Int) -> Double {
        switch pal {
        case 0:
            return 1.2
        case 1:
            return 1.375
        case 2:
            return 1.55
        case 3:
            return 1.725
        default:
            return 1.4
        }
    }
    
    func getExtraSportCaloriePercentage() -> Int {
        guard let extraCaloriePercentage = self.user.extraCaloriePercentage else{
            return 5
        }
        return extraCaloriePercentage
    }
    
    func getPal() -> Int {
        guard let palValue = self.user.pal else{
            return 0
        }
        return palValue
    }
    
    func getPlan() -> PlanType {
        guard let planValue = self.user.plan else{
            return PlanType.Maintenance
        }
        
        switch planValue {
            
        case 0:
            return PlanType.Cut
        case 1:
            return PlanType.Maintenance
        case 2:
            return PlanType.Bulk
        default:
            return PlanType.Maintenance
        }
    }
    
    func getWeight() -> Int {
        guard let weightValue = self.user.weight else{
            return 0
        }
        return weightValue
    }
    
    func getHeight() -> Int {
        guard let heightValue = self.user.height else{
            return 0
        }
        return heightValue
    }
    
    enum Gender{
        case Male, Female
    }
    
    enum PlanType{
        case Cut, Maintenance, Bulk
    }
    
    func getGender() -> Gender {
        guard let gender = self.user.gender else{
            return Gender.Male
        }
        
        switch gender {
        case 0:
            return Gender.Male
        default:
            return Gender.Female
        }
    }
    
    func getDateOfBirth() -> Date {
        guard let dateOfBirth = self.user.dateOfBirth else{
            return Date()
        }
        return dateOfBirth
    }
    
    func getGramsOfProteins() -> Int {

        let weight = getWeight()
        
        if let proteinRatio = self.user.proteinRatio {
            return Int(Double(weight) * proteinRatio)
        } else {
            return Int(weight * (30/100))
        }
    }
    
    func getGramsOfFats(kcal: Int) -> Int {
        
        let fatRatio:Double = (Double(kcal) * 0.3)
        let fatGrams:Int = Int((fatRatio / 9).rounded())
        return fatGrams
    }
    
    func calcKcal() throws {
    
        let plan = getPlan()
        let pal = getPal()
        let weight = getWeight()
        let height = getHeight()
        let gender: Gender = getGender()
        let dateOfBirth = getDateOfBirth()
        let palValue = determinePalValue(pal: pal)
        
        do {
            let ageNumber = try DateHelper.getAgeNumber(dateOfBirth: dateOfBirth)
            
            if gender == .Male {
                
                self.user.restCalories?.kcal = determineCaloriesForMales(weight: weight, height: height, plan: plan, ageNumber: ageNumber, palValue: palValue)
                
                self.setRestMacros()
            }
            else {
                
                self.user.restCalories?.kcal = determineCaloriesForFemales(weight: weight, height: height, plan: plan, ageNumber: ageNumber, palValue: palValue)
                
                self.setRestMacros()
            }
        }
        catch {
            throw UserError.IssueWithCalories
        }
    }
    
    func determineCaloriesForMales(weight: Int, height: Int, plan: PlanType, ageNumber: Int, palValue: Double) -> Int{
        
        let calc1 = 66 + (13.7 * Double(weight))
        let kcal = calc1 + (5 * Double(height)) - (6.8 * Double(ageNumber))
        
        if plan == .Cut{
            return Int((kcal * palValue) * 0.82)
        }
        else if plan == .Maintenance{
            return Int(kcal * palValue)
            }
            else{
                return Int((kcal * palValue) * 1.1)
            }
    }
    
    func determineCaloriesForFemales(weight: Int, height: Int, plan: PlanType, ageNumber: Int, palValue: Double) -> Int{
        
        let calc1 = 447.593 + (9.247 * Double(weight))
        let kcal = calc1 + (3.098 * Double(height)) - (4.33 * Double(ageNumber))
        
        if plan == .Cut{
                return Int((kcal * palValue) * 0.82)
            }
        else if plan == .Maintenance {
                return Int(kcal * palValue)
            }
            else{
                return Int((kcal * palValue) * 1.2)
            }
    }
    
    func calculateCarbs(kcal: Int, protein: Int, fat: Int) -> Int {
        let proteinCalories = protein * 4
        let fatCalories = fat * 9
        return (kcal - proteinCalories - fatCalories)/4
    }
    
    func setRestMacros() {
        
        if let _ = self.user.restCalories {
            //Object already exists
        } else {
            // Create the object
            self.user.restCalories = Macros()
        }
        
        var kcals: Int = self.user.restCalories!.kcal
        let proteins: Int = getGramsOfProteins()
        let fats: Int = getGramsOfFats(kcal: kcals)
        let fibers: Int = Int(Double(kcals) * 0.014)
        let carbs: Int = calculateCarbs(kcal: kcals, protein: proteins, fat: fats)
        
        //reset kcals now
        kcals  = (carbs * 4) + (proteins * 4) + (fats * 9)
        
        self.user.restCalories!.carbs = carbs
        self.user.restCalories!.kcal = kcals
        self.user.restCalories!.protein = proteins
        self.user.restCalories!.fat = fats
        self.user.restCalories!.fiber = fibers
        
        //Overwrite the top level kcal
        self.user.kcal = kcals
        
        //Calculate sport macros as well
        self.setSportMacros()

    }
    
    func setSportMacros() {
        
        if let _ = self.user.sportCalories {
            //Object already exists
        } else {
            // Create the object
            self.user.sportCalories = Macros()
        }
        
        let extraCaloriePercentage = getExtraSportCaloriePercentage()
        let calorieRatio:Double = (Double(extraCaloriePercentage)/100)+1
        let sportCalories:Double = Double(self.user.restCalories!.kcal) * calorieRatio
        
        var kcals: Int = Int(sportCalories)
        let proteins: Int = getGramsOfProteins()
        let fats: Int = getGramsOfFats(kcal: kcals)
        let fibers: Int = Int(sportCalories * 0.014)
        let carbs: Int = calculateCarbs(kcal: kcals, protein: proteins, fat: fats)
        
        //reset kcals now
        kcals  = (carbs * 4) + (proteins * 4) + (fats * 9)
        
        self.user.sportCalories!.kcal = kcals
        self.user.sportCalories!.carbs = carbs
        self.user.sportCalories!.kcal = kcals
        self.user.sportCalories!.protein = proteins
        self.user.sportCalories!.fat = fats
        self.user.sportCalories!.fiber = fibers

    }

}

