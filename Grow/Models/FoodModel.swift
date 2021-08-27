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
                self.setCaloriesForDiary()
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
            self.updateMeal(for: meal)
        }
        return true
    }
    
    func updateMeal(for meal: Meal){
        if self.foodDiary.meals != nil {
            if let mealIndex = self.foodDiary.meals!.firstIndex(where: { $0.id == meal.id }) {
                
                //Reset values
                self.foodDiary.meals![mealIndex].kcal = 0
                self.foodDiary.meals![mealIndex].carbs = 0
                self.foodDiary.meals![mealIndex].protein = 0
                self.foodDiary.meals![mealIndex].fat = 0
                self.foodDiary.meals![mealIndex].fiber = 0
                
                if self.foodDiary.meals![mealIndex].products != nil {
                    for product in self.foodDiary.meals![mealIndex].products! {
                        self.foodDiary.meals![mealIndex].kcal += product.selectedProductDetails?.kcal ?? 0
                        self.foodDiary.meals![mealIndex].carbs += product.selectedProductDetails?.carbs ?? 0
                        self.foodDiary.meals![mealIndex].protein += product.selectedProductDetails?.protein ?? 0
                        self.foodDiary.meals![mealIndex].fat += product.selectedProductDetails?.fat ?? 0
                        self.foodDiary.meals![mealIndex].fiber += product.selectedProductDetails?.fiber ?? 0
                    }
                }
            }
        }
        self.updateUsersCalories()
    }
    
    func deleteMeal(for meal: Meal, with mealIndex: Int) {
            self.foodDiary.meals!.remove(at: mealIndex)
            self.updateMeal(for: meal)
    }
    
    func removeMeal(for meal: Meal){
        if let mealIndex = self.foodDiary.meals!.firstIndex(where: { $0.id == meal.id }) {
            self.foodDiary.meals!.remove(at: mealIndex)
                }
        self.updateMeal(for: meal)
    }
    
    func deleteProductFromMeal(for meal: Meal, with productIndex: Int) {
        if let mealIndex = self.foodDiary.meals!.firstIndex(where: { $0.id == meal.id }) {
            self.foodDiary.meals![mealIndex].products!.remove(at: productIndex)
        }
        self.updateMeal(for: meal)
    }
    
    func getMealIndex(for meal: Meal) -> Int{
        if let mealIndex = self.foodDiary.meals!.firstIndex(where: { $0.id == meal.id }) {
                return mealIndex
            }
            return 0
    }
    
    func updateUsersCalories(){
        
        //Reset all values back to nil by created a clean object
        self.foodDiary.usersCalorieUsed = Calories()
        self.foodDiary.usersCalorieLeftOver = self.foodDiary.usersCalorieBudget
        self.foodDiary.usersCalorieUsedPercentage = CaloriesPercentages()
        
        if self.foodDiary.meals != nil {
            for meal in foodDiary.meals! {
                if meal.products != nil {
                    for product in meal.products! {
                        //First set the calories Used before we calculate the percentages
                        
                        self.foodDiary.usersCalorieUsed.kcal += product.selectedProductDetails?.kcal ?? 0
                        self.foodDiary.usersCalorieLeftOver.kcal = self.foodDiary.usersCalorieBudget.kcal - self.foodDiary.usersCalorieUsed.kcal
                        
                        self.foodDiary.usersCalorieUsed.carbs += product.selectedProductDetails?.carbs ?? 0
                        self.foodDiary.usersCalorieLeftOver.carbs = self.foodDiary.usersCalorieBudget.carbs - self.foodDiary.usersCalorieUsed.carbs
                        
                        self.foodDiary.usersCalorieUsed.protein += product.selectedProductDetails?.protein ?? 0
                        self.foodDiary.usersCalorieLeftOver.protein = self.foodDiary.usersCalorieBudget.protein - self.foodDiary.usersCalorieUsed.protein
                        
                        self.foodDiary.usersCalorieUsed.fat += product.selectedProductDetails?.fat ?? 0
                        self.foodDiary.usersCalorieLeftOver.fat = self.foodDiary.usersCalorieBudget.fat - self.foodDiary.usersCalorieUsed.fat
                        
                        self.foodDiary.usersCalorieUsed.fiber += product.selectedProductDetails?.fiber ?? 0
                        self.foodDiary.usersCalorieLeftOver.fiber = self.foodDiary.usersCalorieBudget.fiber - self.foodDiary.usersCalorieUsed.fiber
                    }
                }
            }
        }
        self.updateUsersCaloriePercentages()
    }
    
    func updateUsersCaloriePercentages(){
        self.foodDiary.usersCalorieUsedPercentage.kcal = Float(self.foodDiary.usersCalorieUsed.kcal) / Float(self.foodDiary.usersCalorieBudget.kcal)
        
        self.foodDiary.usersCalorieUsedPercentage.carbs = Float(self.foodDiary.usersCalorieUsed.carbs) / Float(self.foodDiary.usersCalorieBudget.carbs)
        
        self.foodDiary.usersCalorieUsedPercentage.protein = Float(self.foodDiary.usersCalorieUsed.protein) / Float(self.foodDiary.usersCalorieBudget.protein)
        
        self.foodDiary.usersCalorieUsedPercentage.fat = Float(self.foodDiary.usersCalorieUsed.fat) / Float(self.foodDiary.usersCalorieBudget.fat)
        
        self.foodDiary.usersCalorieUsedPercentage.fiber = Float(self.foodDiary.usersCalorieUsed.fiber) / Float(self.foodDiary.usersCalorieBudget.fiber)
    }
    
    func setCaloriesForDiary(){
        self.foodDiary.usersCalorieBudget.kcal = self.user.kcal ?? 0
        self.foodDiary.usersCalorieBudget.carbs = self.calcCarbs()
        self.foodDiary.usersCalorieBudget.protein = self.calcProtein()
        self.foodDiary.usersCalorieBudget.fat = self.calcFat()
        self.foodDiary.usersCalorieBudget.fiber = self.calcFiber()
        
        //Initiate the usersCalorieLeftOver and set it equal to the budget the first time
        self.foodDiary.usersCalorieLeftOver = self.foodDiary.usersCalorieBudget
    }
    
    
    func calcProtein() -> Int {
        return Int(Double(self.user.weight ?? 1) * 1.9)
    }

    func calcFat() -> Int {
        return Int(Double(self.user.kcal ?? 1) * 0.3/9)

    }

    func calcCarbs() -> Int {
        let proteinGrams:Int = self.calcProtein()
        let fatGrams:Int = self.calcFat()
        let proteinKcal = proteinGrams * 4
        let fatKcal = fatGrams * 9
        return Int(((self.user.kcal ?? 1) - proteinKcal - fatKcal)/4)
    }

    func calcFiber() -> Int {
        return Int(Double(self.user.kcal ?? 1) * 0.014)
    }

}


struct Calories: Codable, Hashable, Identifiable {
    var id = UUID()
    var kcal: Int
    var carbs: Int
    var protein: Int
    var fat: Int
    var fiber: Int
    
    init(kcal: Int = 0, carbs: Int = 0, protein: Int = 0, fat: Int = 0, fiber: Int = 0){
        self.kcal = kcal
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.fiber = fiber
    }
}

struct CaloriesPercentages: Codable, Hashable, Identifiable {
    var id = UUID()
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
    var usersCalorieBudget: Calories
    var usersCalorieUsed: Calories
    var usersCalorieLeftOver: Calories
    var usersCalorieUsedPercentage: CaloriesPercentages
    
    init(id:UUID = UUID(),meals: [Meal]? = [Meal()], date: Date = Date(), usersCalorieBudget: Calories = Calories(), usersCalorieUsed: Calories = Calories(), usersCalorieLeftOver: Calories = Calories(), usersCalorieUsedPercentage: CaloriesPercentages = CaloriesPercentages()){
        self.id = id
        self.meals = meals
        self.date = date
        self.usersCalorieBudget = usersCalorieBudget
        self.usersCalorieUsed = usersCalorieUsed
        self.usersCalorieLeftOver = usersCalorieLeftOver
        self.usersCalorieUsedPercentage = usersCalorieUsedPercentage
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
