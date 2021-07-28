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
    
    func getTodaysIntake(for budget: UserDataModel){
        
        
        //Firbase call but for now some hardcoding
        self.userIntake.kcal = 2040
        self.userIntake.carbs = 325
        self.userIntake.protein = 125
        self.userIntake.fat = 20
        self.userIntake.fiber = 30
        
        self.userIntakeLeftOvers.kcal = self.userIntake.kcal / Float(budget.user.kcal ?? 0)
        self.userIntakeLeftOvers.carbs = self.userIntake.carbs / Float(budget.user.carbs ?? 0)
        self.userIntakeLeftOvers.protein = self.userIntake.protein / Float(budget.user.protein ?? 0)
        self.userIntakeLeftOvers.fat = self.userIntake.fat / Float(budget.user.fat ?? 0)
        self.userIntakeLeftOvers.fiber = self.userIntake.fiber / Float(budget.user.fiber ?? 0)
    }

}

struct BudgetLeftOver{
    var kcal: Float
    var carbs: Float
    var protein: Float
    var fat: Float
    var fiber: Float
    
    init(kcal: Float = 0, carbs: Float = 0, protein: Float = 0, fat: Float = 0, fiber: Float = 0){
        self.kcal = kcal
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.fiber = fiber
    }
}

struct UserIntake{
    var date: Date?
    var kcal: Float
    var carbs: Float
    var protein: Float
    var fat: Float
    var fiber: Float
    
    init(kcal: Float = 0, carbs: Float = 0, protein: Float = 0, fat: Float = 0, fiber: Float = 0){
        self.kcal = kcal
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.fiber = fiber
    }
}
