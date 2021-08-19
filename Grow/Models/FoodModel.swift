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
    @Published var dailyIntake = DailyIntake()
    
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
    
    func addMeal(){
        if  self.dailyIntake.meals == nil {
            self.dailyIntake.meals? = [Meal]()
        } else {
        self.dailyIntake.meals?.append(Meal())
        }
        print(self.dailyIntake.meals)
    }
    
    func getMealIndex(for meal: Meal) -> Int{
        if let mealIndex = self.dailyIntake.meals!.firstIndex(where: { $0.id == meal.id }) {
                return mealIndex
            }
            return 0
    }
    
    func removeMeal(for meal: Meal){
        if let mealIndex = self.dailyIntake.meals!.firstIndex(where: { $0.id == meal.id }) {
            self.dailyIntake.meals!.remove(at: mealIndex)
                }
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

struct DailyIntake: Codable, Hashable, Identifiable {
    var id = UUID()
    var meals: [Meal]?
    var date: Date
    
    init(id:UUID = UUID(),meals: [Meal]? = [Meal()], date: Date = DateHelper.from(year: 2020, month: 1, day: 1)){
        self.id = id
        self.meals = meals
        self.date = date
    }
}

struct Meal: Codable, Hashable, Identifiable {
    var id = UUID()
    var product: [Product]?
}

struct Product: Codable, Hashable, Identifiable{
    var id = UUID()
    var kcal: Int
    var carbs: Int
    var protein: Int
    var fat: Int
    var fiber: Int
    
    
}
