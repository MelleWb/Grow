//
//  User.swift
//  Grow
//
//  Created by Swen Rolink on 30/11/2021.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

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
    var proteinRatio: Double?
    var fatRatio: Double?
    var nmbrOfTrainings: Int?
    var pal: Int?
    var fcmToken: String?
    var schema: String?
    var weekPlan: [DayPlan]?
    var workoutOfTheDay: UUID?

    var restCalories: Macros?
    var sportCalories: Macros?
    var extraCaloriePercentage: Int?
}


struct UserImages {
    var userImage: UIImage?
    var coachImage: UIImage?
}

struct DayPlan: Codable, Identifiable, Hashable {
    var id = UUID()
    var trainingType: String?
    var routine: UUID?
    var isTrainingDay: Bool?
}

struct BodyMeasurement: Codable, Identifiable, Hashable {
    
    var id = UUID()
    var date: Date
    @DocumentID var documentID: String?
    
    var smallFrontImageUrl: String
    var smallSideImageUrl: String
    var smallBackImageUrl: String
    
    var largeFrontImageUrl: String
    var largeSideImageUrl: String
    var largeBackImageUrl: String
    
    var weight: Double? = 0
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        documentID:String? = nil,
        smallFrontImageUrl: String = "",
        smallSideImageUrl: String = "",
        smallBackImageUrl: String = "",
        largeFrontImageUrl: String = "",
        largeSideImageUrl: String = "",
        largeBackImageUrl: String = "",
        weight: Double? = 0
    ){
        self.id = id
        self.date = date
        self.documentID = documentID
        self.smallFrontImageUrl = smallFrontImageUrl
        self.smallSideImageUrl = smallSideImageUrl
        self.smallBackImageUrl = smallBackImageUrl
        self.largeFrontImageUrl = largeFrontImageUrl
        self.largeSideImageUrl = largeSideImageUrl
        self.largeBackImageUrl = largeBackImageUrl
        self.weight = weight
    }
}
