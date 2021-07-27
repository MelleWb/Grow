//
//  FoodModel.swift
//  Grow
//
//  Created by Swen Rolink on 27/07/2021.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift


class FoodDataModel: ObservableObject{
    
    @Published var userIntake =  UserIntake()
    
    
    func getTodaysIntake(){
        //Firbase call
        self.userIntake.kcal = 0.3
    }
}


struct UserIntake{
    var kcal: Float
    var carbs: Int?
    var protein: Int?
    var fat: Int?
    var fiber: Int?
    
    init(kcal: Float = 0){
        self.kcal = kcal
    }
}
