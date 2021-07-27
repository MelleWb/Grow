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
    @Published var userIntakeLeftOvers = BudgetLeftOver()
    
    func getTodaysIntake(usersKcalBudget: Int){
        //Firbase call
        self.userIntake.kcal = 2400
        
        self.userIntakeLeftOvers.kcal = self.userIntake.kcal / Float(usersKcalBudget)
        
        print (usersKcalBudget)
        print (self.userIntakeLeftOvers.kcal)
    }

}

struct BudgetLeftOver{
    var kcal: Float
    var carbs: Int?
    var protein: Int?
    var fat: Int?
    var fiber: Int?
    
    init(kcal: Float = 0){
        self.kcal = kcal
    }
}

struct UserIntake{
    var date: Date?
    var kcal: Float
    var carbs: Int?
    var protein: Int?
    var fat: Int?
    var fiber: Int?
    
    init(kcal: Float = 0){
        self.kcal = kcal
    }
}
