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
    @Published var foodDiary = FoodDiary()
    @Published var products = [Product()]
    var user = User()
    
    init(){
        self.initiateFoodModel()
    }
    
    func initiateFoodModel(){
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        let docRef = db.collection("users").document(Auth.auth().currentUser!.uid)

        docRef.getDocument(source: .cache) { (document, error) in
          if let document = document {
            do{
                self.user = try document.data(as: User.self)!
                
                //
            }
            catch {
              print(error)
            }
          } else {
            print("Document does not exist in cache")
          }
        }
    }
    
    func createProduct(product: Product) -> Bool{
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        let newProdRef = db.collection("foodProducts").document()
        
        do {
          try newProdRef.setData(from: product, merge: true)
            return true
        }
        catch {
          print(error)
            return false
        }
    }
    
    func fetchProducts(){
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        
        db.collection("foodProducts").addSnapshotListener { (querySnapshot, error) in

                guard let documents = querySnapshot?.documents else {
                        print("No documents")
                    return
                }
                
                self.products = documents.map { (queryDocumentSnapshot) -> Product in
                    
                    let result = Result {
                        try queryDocumentSnapshot.data(as: Product.self)
                    }
                    switch result {
                    case .success(let stats):
                        if let stats = stats {
                            return stats
                        }
                        else {
                            print ("Document does not exists")
                        }
                    case .failure(let error):
                        print("error decoding schema: \(error)")
                    }
                    return Product()
                }
            }
    }
    
    func getTodaysIntake(for budget: UserDataModel){
        
        
        //Firbase call but for now some hardcoding
        self.userIntake.kcal = 2040
        self.userIntake.carbs = 325
        self.userIntake.protein = 125
        self.userIntake.fat = 20
        self.userIntake.fiber = 30
        
        self.userIntakeLeftOvers.kcal = self.userIntake.kcal / Float(budget.user.kcal ?? 0)
        //self.userIntakeLeftOvers.carbs = self.userIntake.carbs / Float(budget.user.carbs ?? 0)
        //self.userIntakeLeftOvers.protein = self.userIntake.protein / Float(budget.user.protein ?? 0)
        //self.userIntakeLeftOvers.fat = self.userIntake.fat / Float(budget.user.fat ?? 0)
        //self.userIntakeLeftOvers.fiber = self.userIntake.fiber / Float(budget.user.fiber ?? 0)
    }
    
    func addMeal(){
        if  self.foodDiary.meals == nil {
            self.foodDiary.meals? = [Meal]()
        } else {
        self.foodDiary.meals?.append(Meal())
        }
        print(self.foodDiary.meals)
    }
    
    func getMealIndex(for meal: Meal) -> Int{
        if let mealIndex = self.foodDiary.meals!.firstIndex(where: { $0.id == meal.id }) {
                return mealIndex
            }
            return 0
    }
    
    func removeMeal(for meal: Meal){
        if let mealIndex = self.foodDiary.meals!.firstIndex(where: { $0.id == meal.id }) {
            self.foodDiary.meals!.remove(at: mealIndex)
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

struct FoodDiary: Codable, Hashable, Identifiable {
    var id = UUID()
    var meals: [Meal]?
    var date: Date
    
    init(id:UUID = UUID(),meals: [Meal]? = [Meal()], date: Date = Date()){
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
    var name: String
    var kcal: Int
    var carbs: Int
    var protein: Int
    var fat: Int
    var fiber: Int
    var unit: String
    var portions: [ProductPortion]
    
    init(id:UUID = UUID(), name:String = "", kcal:Int = 0, carbs:Int = 0, protein:Int = 0, fat:Int = 0, fiber:Int = 0, unit:String = "Grammen", portions:[ProductPortion] = [ProductPortion(name: "Standaard", amount: 100)]){
        self.id = id
        self.name = name
        self.kcal = kcal
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.fiber = fiber
        self.unit = unit
        self.portions = portions
    }
}

struct ProductPortion: Codable, Hashable, Identifiable{
    var id = UUID()
    var name: String
    var amount: Int
    
    init(id:UUID = UUID(), name:String = "", amount:Int = 0){
        self.id = id
        self.name = name
        self.amount = amount
    }
}
