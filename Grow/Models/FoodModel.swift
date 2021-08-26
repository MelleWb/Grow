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
    
    @Published var diaryForView = FoodDiary ()
    @Published var foodDiary = FoodDiary()
    
    @Published var products = [Product()]
    var user = User()
    
    @Published var todaysDiary = [FoodDiary()]
    @Published var otherDaysIntake = [FoodDiary()]
    
    init(){
        self.initiateFoodModel()
        self.getTodaysFoodDiary()
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
                
                
            }
            catch {
              print(error)
            }
          } else {
            print("Document does not exist in cache")
          }
        }
    }
    
    func getFoodDiaryForDate(for date: Date){
        //First detach the listener
        
        //Now do create a new listener
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        let docRef = db.collection("users").document(Auth.auth().currentUser!.uid).collection("foodDiary")
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let start = calendar.date(from: components)!
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        let queryRef = docRef
           .whereField("created", isGreaterThan: start)
           .whereField("created", isLessThan: end)
            .limit(to: 1)
        
        queryRef.addSnapshotListener { (querySnapshot, error) in

                    guard let documents = querySnapshot?.documents else {
                            print("No documents")
                        return
                    }
            
            self.todaysDiary = documents.map { (querySnapshot) -> FoodDiary in
                
                let result = Result {
                    try querySnapshot.data(as: FoodDiary.self)
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
                return FoodDiary()
            }
        }
    }
    
    func getTodaysFoodDiary(){
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        let docRef = db.collection("users").document(Auth.auth().currentUser!.uid).collection("foodDiary")
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let start = calendar.date(from: components)!
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        let queryRef = docRef
           .whereField("created", isGreaterThan: start)
           .whereField("created", isLessThan: end)
            .limit(to: 1)
        
        queryRef.addSnapshotListener { (querySnapshot, error) in

                    guard let documents = querySnapshot?.documents else {
                            print("No documents")
                        return
                    }
            
            self.todaysDiary = documents.map { (querySnapshot) -> FoodDiary in
                
                let result = Result {
                    try querySnapshot.data(as: FoodDiary.self)
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
                return FoodDiary()
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
    }
    
    func addProductToMeal(for meal: Meal, with product: Product, with selectedSize: SelectedProductDetails) -> Bool{

        var newProduct:Product = product
        newProduct.selectedProductDetails = selectedSize
        
        if let mealIndex = self.foodDiary.meals!.firstIndex(where: { $0.id == meal.id }) {
            if self.foodDiary.meals![mealIndex].products != nil {
                if let productIndex = self.foodDiary.meals![mealIndex].products!.firstIndex(where: { $0.id == product.id }) {
                    self.foodDiary.meals![mealIndex].products![productIndex] = product
                } else {
                self.foodDiary.meals![mealIndex].products!.append(newProduct)
                }
            }else {
                self.foodDiary.meals![mealIndex].products = [(newProduct)]
            }
            self.foodDiary.meals![mealIndex].kcal += selectedSize.kcal
            self.foodDiary.meals![mealIndex].carbs += selectedSize.carbs
            self.foodDiary.meals![mealIndex].protein += selectedSize.protein
            self.foodDiary.meals![mealIndex].fat += selectedSize.fat
            self.foodDiary.meals![mealIndex].fiber += selectedSize.fiber
        }
        return true
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
    var date: Date
    var kcal: Float
    var carbs: Float
    var protein: Float
    var fat: Float
    var fiber: Float
    
    init(date: Date = Date(), kcal: Float = 0, carbs: Float = 0, protein: Float = 0, fat: Float = 0, fiber: Float = 0){
        self.date = date
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
    var name: String?
    var products: [Product]?
    var kcal:Int
    var carbs: Int
    var protein: Int
    var fat: Int
    var fiber: Int
    
    init(id:UUID = UUID(), name: String? = nil, products:[Product]? = nil, kcal:Int = 0, carbs:Int = 0, protein:Int = 0, fat:Int = 0, fiber:Int = 0){
        self.id = id
        self.name = name
        self.products = products
        self.kcal = kcal
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.fiber = fiber
    }
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
    var selectedProductDetails : SelectedProductDetails?
    
    init(id:UUID = UUID(), name:String = "", kcal:Int = 0, carbs:Int = 0, protein:Int = 0, fat:Int = 0, fiber:Int = 0, unit:String = "Grammen", portions:[ProductPortion] = [ProductPortion(name: "Standaard", amount: 100)], selectedProductDetails: SelectedProductDetails? = nil){
        self.id = id
        self.name = name
        self.kcal = kcal
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.fiber = fiber
        self.unit = unit
        self.portions = portions
        self.selectedProductDetails = selectedProductDetails
    }
}

struct SelectedProductDetails: Codable, Hashable, Identifiable{
    var id = UUID()
    var kcal: Int
    var carbs: Int
    var protein: Int
    var fat: Int
    var fiber: Int
    var amount: Int
    
    init(id:UUID = UUID(), kcal:Int = 0, carbs:Int = 0, protein:Int = 0, fat:Int = 0, fiber:Int = 0, amount:Int = 0){
        self.id = id
        self.kcal = kcal
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.fiber = fiber
        self.amount = amount
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
