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
    
    @Published var date: Date = Date()
    
    @Published var foodDiary = FoodDiary()
    @Published var products = [Product()]
    var user = User()
    var foodDiaryListener: ListenerRegistration? = nil
    
    @Published var todaysDiary = FoodDiary()
    @Published var otherDaysIntake = [FoodDiary()]
    
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
                self.getFoodDiary()
            }
            catch {
              print(error)
            }
          } else {
            print("Document does not exist in cache")
          }
        }
    }
    
    func dateHasChanged(){
        //Set the calories right
        
        
        let isToday = Calendar.current.isDateInToday(self.date)
        
        if isToday{
            //set the foodDiary to todaysDiary
            //Remove listener first
            self.foodDiaryListener!.remove()
            
            //Now fetch results
            self.foodDiary = FoodDiary()
            self.setCaloriesForDiary()
            self.getFoodDiary()
            self.foodDiary = self.todaysDiary
        } else {
            //Remove listener first
            self.foodDiaryListener!.remove()
            
            //Now fetch results
            self.foodDiary = FoodDiary()
            self.setCaloriesForDiary()
            self.getFoodDiary()
        }
    }
    
    func getDayOfWeekAsNumber(date: Date) -> Int{
        let dayOfWeek = Calendar.current.component(.weekday, from: date)
        let dayOfWeekString:String = Calendar.current.weekdaySymbols[dayOfWeek-1]
        
        if dayOfWeekString == "Sunday"{
            return 6
        }
        else {
            return dayOfWeek - 2
        }
        
    }
    
    func getFoodDiary(){
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        let docRef = db.collection("users").document(Auth.auth().currentUser!.uid).collection("foodDiary")
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let start = calendar.date(from: components)!
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        let queryRef = docRef
           .whereField("date", isGreaterThan: start)
           .whereField("date", isLessThan: end)
            .limit(to: 1)
        
        foodDiaryListener = queryRef.addSnapshotListener { (querySnapshot, error) in
            
                    guard let documents = querySnapshot?.documents else {
                            print("No documents")
                        return
                    }
            
            let _:[FoodDiary] = documents.map { (querySnapshot) -> FoodDiary in
                
                let result = Result {
                    try querySnapshot.data(as: FoodDiary.self)
                }
                switch result {
                case .success(let stats):
                    if let stats = stats {
                        
                        self.foodDiary = stats
                        return stats
                    }
                    else {
                        print ("Document does not exists")
                    }
                case .failure:
                    print("error decoding schema...")
                }
                return FoodDiary()
            }
            self.setCaloriesForDiary()
            self.updateUsersCalories()
            let isToday = Calendar.current.isDateInToday(self.date)
            if isToday{
                self.todaysDiary =  self.foodDiary
            }
        }
    }
    
    func copyMeal(meal: Meal){
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        let docRef = db.collection("users").document(Auth.auth().currentUser!.uid).collection("foodDiary")
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let start = calendar.date(from: components)!
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        let queryRef = docRef
           .whereField("date", isGreaterThan: start)
           .whereField("date", isLessThan: end)
            .limit(to: 1)

            queryRef.getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    if querySnapshot!.documents.count > 0 {
                        for document in querySnapshot!.documents {
                            do{
                                var diaryToCopyInto: FoodDiary = try document.data(as: FoodDiary.self)!
                                if diaryToCopyInto.meals == nil {
                                    diaryToCopyInto.meals = [meal]
                                } else {
                                    diaryToCopyInto.meals!.append(meal)
                                }
                                do {
                                    try docRef.document(document.documentID).setData(from: diaryToCopyInto, merge: true)
                                }
                                catch {
                                  print(error)
                                }
                            }
                            catch{
                                print("error")
                            }
                        }
                    } else {
                        var diaryToCopyInto: FoodDiary = FoodDiary()
                        //set the meal to the created diary and set the date correct
                        diaryToCopyInto.meals = [meal]
                        diaryToCopyInto.date = self.date
                            do {
                                try docRef.document().setData(from: diaryToCopyInto)
                            }
                            catch {
                              print(error)
                            }
                    }
                }
            }
            //self.saveCopiedMeal(meal: meal)
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
    
    func saveDiary(){
        
        //Make sure the date of the foodDiary is right
        self.foodDiary.date = self.date
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        let diaryRef = db.collection("users").document(Auth.auth().currentUser!.uid).collection("foodDiary")
        
        if self.foodDiary.id == "" {
            print("I create a document")
            let newDiary = diaryRef.document()
            
            do {
                try newDiary.setData(from: self.foodDiary, merge: true)
            }
            catch {
              print(error)
            }
        } else {
            print("I reuse a document")
            let documentID = self.foodDiary.id!
            let existingDiary = diaryRef.document(documentID)
            do {
                try existingDiary.setData(from: self.foodDiary, merge: true)
            }
            catch {
              print(error)
            }
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
    
    func saveCopiedMeal(meal: Meal){

        let isToday = Calendar.current.isDateInToday(self.date)

        if self.foodDiary.meals == nil || self.foodDiary.meals!.isEmpty{
            self.foodDiary.meals = [meal]
        } else {
            self.foodDiary.meals!.append(meal)
        }
        
        if isToday{
            self.todaysDiary =  self.foodDiary
        }
        
        self.setCaloriesForDiary()
        saveDiary()
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
        self.setCaloriesForDiary()
        self.updateUsersCalories()
        self.saveDiary()
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
        var kcal:Int = 0
        let dayOfWeek = self.getDayOfWeekAsNumber(date: self.date)

        if user.weekPlan![dayOfWeek].isTrainingDay!{
            kcal = Int((Double(self.user.kcal ?? 0) * 1.1).rounded())
        } else {
            kcal = self.user.kcal ?? 0
        }
        
        self.foodDiary.usersCalorieBudget.kcal = kcal
        self.foodDiary.usersCalorieBudget.carbs = self.calcCarbs(kcal: kcal)
        self.foodDiary.usersCalorieBudget.protein = self.calcProtein()
        self.foodDiary.usersCalorieBudget.fat = self.calcFat(kcal: kcal)
        self.foodDiary.usersCalorieBudget.fiber = self.calcFiber(kcal: kcal)
        
        //Initiate the usersCalorieLeftOver and set it equal to the budget the first time
        self.foodDiary.usersCalorieLeftOver = self.foodDiary.usersCalorieBudget
    }
    
    
    func calcProtein() -> Int {
        return Int(Double(self.user.weight ?? 1) * 2)
    }

    func calcFat(kcal: Int) -> Int {
        return Int(Double(kcal) * 0.3/9)

    }

    func calcCarbs(kcal: Int) -> Int {
        let proteinGrams:Int = self.calcProtein()
        let fatGrams:Int = self.calcFat(kcal: kcal)
        let proteinKcal = proteinGrams * 4
        let fatKcal = fatGrams * 9
        return Int((kcal - proteinKcal - fatKcal)/4)
    }

    func calcFiber(kcal: Int) -> Int {
        return Int(Double(kcal) * 0.014)
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
    @DocumentID var id: String?
    var meals: [Meal]?
    var date: Date
    var usersCalorieBudget: Calories
    var usersCalorieUsed: Calories
    var usersCalorieLeftOver: Calories
    var usersCalorieUsedPercentage: CaloriesPercentages
    
    init(id:String? = "",meals: [Meal]? = [Meal()], date: Date = Date(), usersCalorieBudget: Calories = Calories(), usersCalorieUsed: Calories = Calories(), usersCalorieLeftOver: Calories = Calories(), usersCalorieUsedPercentage: CaloriesPercentages = CaloriesPercentages()){
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
    @DocumentID var documentID: String?
    var name: String
    var kcal: Int
    var carbs: Int
    var protein: Int
    var fat: Int
    var fiber: Int
    var unit: String
    var portions: [ProductPortion]
    var selectedProductDetails : SelectedProductDetails?
    
    init(id:UUID = UUID(), documentID:String? = "", name:String = "", kcal:Int = 0, carbs:Int = 0, protein:Int = 0, fat:Int = 0, fiber:Int = 0, unit:String = "Grammen", portions:[ProductPortion] = [ProductPortion(name: "Standaard", amount: 100)], selectedProductDetails: SelectedProductDetails? = nil){
        self.id = id
        self.documentID = documentID
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
