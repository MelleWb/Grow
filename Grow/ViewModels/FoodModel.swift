//
//  FoodModel.swift
//  Grow
//
//  Created by Swen Rolink on 27/07/2021.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore


class FoodDataModel: ObservableObject{
    
    @Published var date: Date = Date()
    
    @Published var foodDiary = FoodDiary()
    @Published var products = [Product()]
    @Published var savedMeals = [Meal()]
    
    @Published var slimProductList = SlimProductList()
    
    var user = User()
    var foodDiaryListener: ListenerRegistration? = nil
    var mealListener: ListenerRegistration? = nil
    var productListener: ListenerRegistration? = nil
    
    @Published var todaysDiary = FoodDiary()
    @Published var otherDaysIntake = [FoodDiary()]
    private let sessionProvider: SessionProviding
    private let userRepository: UserRepository
    private let foodDataLoader: FoodDataLoading
    private let foodDataWriter: FoodDataWriting
    private let runStartupSideEffects: Bool
    
    private enum ErrorType : Error {
        case NullPointer
    }
    
    init(
        sessionProvider: SessionProviding = FirebaseSessionProvider(),
        userRepository: UserRepository = FirestoreUserRepository(),
        foodDataLoader: FoodDataLoading = FirestoreFoodDataLoader(),
        foodDataWriter: FoodDataWriting = FirestoreFoodDataWriter(),
        autostart: Bool = true,
        runStartupSideEffects: Bool = true
    ){
        self.sessionProvider = sessionProvider
        self.userRepository = userRepository
        self.foodDataLoader = foodDataLoader
        self.foodDataWriter = foodDataWriter
        self.runStartupSideEffects = runStartupSideEffects

        if autostart {
            self.initiateFoodModel()
        }
    }
    
    func  resetUser(user:  User){
        self.user = user
        self.getFoodDiary()
    }
    
    func initiateFoodModel(){
        guard let uid = sessionProvider.currentUserID else {
            return
        }

        userRepository.fetchUser(uid: uid) { result in
            switch result {
            case .success(let user):
                self.user = user

                guard self.runStartupSideEffects else {
                    return
                }

                self.getFoodDiary()
                self.fetchSlimProductList()
                self.getMeals()
            case .failure(let error):
                print(error)
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
        
        if dayOfWeek == 1{
            return 6
        }
        else {
            return dayOfWeek - 2
        }
        
    }
    
    func getFoodDiary(){
        guard let userID = sessionProvider.currentUserID else {
            return
        }

        foodDiaryListener = foodDataLoader.observeFoodDiary(userID: userID, date: date) { result in
            switch result {
            case .success(let diary):
                self.foodDiary = diary ?? FoodDiary()
            case .failure:
                print("error decoding schema...")
                self.foodDiary = FoodDiary()
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
        guard let userID = sessionProvider.currentUserID else {
            return
        }

        foodDataWriter.copyMeal(userID: userID, date: date, meal: meal) { result in
            if case .failure(let error) = result {
                print(error)
            }
        }
    }
    
    func createProduct(product: Product) -> Bool{
        var slimProductList = self.slimProductList
        var slimProduct: SlimProduct?

        let documentID = (product.documentID?.isEmpty == false) ? product.documentID! : UUID().uuidString

        if let slimProdIndex:Int = self.slimProductList.products.firstIndex(where: { $0.documentID == documentID }){
            slimProduct = self.slimProductList.products[slimProdIndex]
            slimProduct!.name = product.name
            slimProductList.products.remove(at: slimProdIndex)
            slimProductList.products.append(slimProduct!)
        } else {
            slimProduct = SlimProduct(documentID: documentID, name: product.name)
            slimProductList.products.append(slimProduct!)
        }

        var productToSave = product
        productToSave.documentID = documentID

        var success = true
        foodDataWriter.saveProduct(productToSave, slimProductList: slimProductList) { result in
            if case .failure(let error) = result {
                print(error)
                success = false
            }
        }
        return success
    }
    
    func deleteProduct(documentID: String){
        var slimProductList = self.slimProductList

        if let slimProdIndex:Int = slimProductList.products.firstIndex(where: { $0.documentID == documentID }){
            slimProductList.products.remove(at: slimProdIndex)
        }

        foodDataWriter.deleteProduct(documentID: documentID, slimProductList: slimProductList) { result in
            if case .failure(let error) = result {
                print("Error removing document: \(error)")
            }
        }
    }
    
    func getProductDetails(documentID: String, completion: @escaping(Product?, String) -> Void) {
        
        let db = Firestore.firestore()
        var returnProduct: Product = Product()
        
        db.collection("foodProducts").document(documentID).getDocument { documentSnapShot, err in
            
            guard let document = documentSnapShot else {
                    print("No documents")
                    completion(nil, "Error")
                return
            }
            
            do {
                returnProduct = try document.data(as: Product.self)
                completion(returnProduct, "")
            } catch {
                print("Error in parsing the product document")
                completion(nil, "Error")
            }
        }
    }
    
    func saveDiary() {
        guard let userID = sessionProvider.currentUserID else {
            return
        }

        self.foodDiary.date = self.date
        foodDataWriter.saveDiary(userID: userID, diary: self.foodDiary) { result in
            if case .failure(let error) = result {
                print(error)
            }
        }
    }
    
    func getMeals(){
        mealListener = foodDataLoader.observeMeals { result in
            switch result {
            case .success(let meals):
                self.savedMeals = meals
            case .failure:
                print("error decoding schema...")
                self.savedMeals = []
            }
        }
    }
    
    func saveMeal(for meal: Meal) -> Bool {
        var success = true
        foodDataWriter.saveMeal(meal) { result in
            if case .failure(let error) = result {
                print(error)
                success = false
            }
        }
        return success
    }
    
//    func fetchProducts(){
//
//        let settings = FirestoreSettings()
//        settings.isPersistenceEnabled = true
//        let db = Firestore.firestore()
//
//
//        productListener = db.collection("foodProducts").addSnapshotListener { (querySnapshot, error) in
//
//                guard let documents = querySnapshot?.documents else {
//                        print("No documents")
//                    return
//                }
//
//                self.products = documents.map { (queryDocumentSnapshot) -> Product in
//
//                    let result = Result {
//                        try queryDocumentSnapshot.data(as: Product.self)
//                    }
//                    switch result {
//                    case .success(let stats):
//                        if let stats = stats {
//                            return stats
//                        }
//                        else {
//                            print ("Document does not exists")
//                        }
//                    case .failure(let error):
//                        print("error decoding schema: \(error)")
//                    }
//                    return Product()
//                }
//            }
//    }
    
    func fetchSlimProductList() {
        productListener = foodDataLoader.observeSlimProductList { result in
            switch result {
            case .success(let slimProductList):
                self.slimProductList = slimProductList
            case .failure:
                print("error in parsing slim document list")
            }
        }
    }
    
    func mergeSlimProductList() {
        
        //MARK: Only use this to completely overwrite the SlimProductList
        
        let db = Firestore.firestore()
        
        let prodRef = db.collection("foodOverview").document("dA3UCyGYWDHRumopuAAg")
        
        //Clean up the published var
        self.slimProductList = SlimProductList()
        
        //Set the published var to a var for this method
        var productList = self.slimProductList
        
        //Loop through products and set the product
        for product in self.products {
            let product: SlimProduct = SlimProduct(documentID: product.documentID ?? "", name: product.name)
            productList.products.append(product)
        }
        
        do {
            try prodRef.setData(from: productList, merge: true)
            
        } catch {
            print("error")
        }
    }
    
    func addMeal(){
        if  self.foodDiary.meals == nil {
            self.foodDiary.meals? = [Meal]()
        } else {
        self.foodDiary.meals?.append(Meal())
        }
    }
    
    func addSavedMeal(meal: Meal){
        if  self.foodDiary.meals == nil {
            self.foodDiary.meals? = [meal]
        } else {
        self.foodDiary.meals?.append(meal)
        }
        self.updateMeal(for: meal)
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
    
    func updateMealName(for meal: Meal, name: String) {
        if let mealIndex = self.foodDiary.meals!.firstIndex(where: { $0.id == meal.id }) {
            print(name)
            self.foodDiary.meals![mealIndex].name = name
            self.updateMeal(for: meal)
        }
    }
    
    func updateProductInMeal(for meal: Meal, with product: Product, with selectedSize: SelectedProductDetails) -> Bool{
        if let mealIndex = self.foodDiary.meals!.firstIndex(where: { $0.id == meal.id }) {
            if self.foodDiary.meals![mealIndex].products != nil {
                if let productIndex = self.foodDiary.meals![mealIndex].products!.firstIndex(where: { $0.id == product.id }) {
                    self.foodDiary.meals![mealIndex].products![productIndex].selectedProductDetails = selectedSize
                    self.updateMeal(for: meal)
                    return true
                }
            }
        }
        return false
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
        
        if self.foodDiary.meals == nil {
            self.foodDiary.meals = [Meal()]
        }
        
        self.updateMeal(for: meal)
    }
    
    func deleteProductFromMeal(for meal: Meal, with productIndex: Int) {
        if let mealIndex = self.foodDiary.meals!.firstIndex(where: { $0.id == meal.id }) {
            self.foodDiary.meals![mealIndex].products!.remove(at: productIndex)
        }
        self.updateMeal(for: meal)
    }
    
    func getMealIndex(for meal: Meal) -> Int?{
        if let mealIndex = self.foodDiary.meals!.firstIndex(where: { $0.id == meal.id }) {
                return mealIndex
            }
        else {
            return nil
        }
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

        let dayOfWeek = self.getDayOfWeekAsNumber(date: self.date)

        self.foodDiary.usersCalorieBudget = Self.calorieBudget(for: self.user, dayOfWeek: dayOfWeek)
        
        //Initiate the usersCalorieLeftOver and set it equal to the budget the first time
        self.foodDiary.usersCalorieLeftOver = self.foodDiary.usersCalorieBudget
    }

    static func calorieBudget(for user: User, dayOfWeek: Int) -> Calories {
        let trainingDay = user.weekPlan?.indices.contains(dayOfWeek) == true && user.weekPlan?[dayOfWeek].isTrainingDay == true
        let sourceMacros = trainingDay ? user.sportCalories : user.restCalories

        return Calories(
            kcal: Double(sourceMacros?.kcal ?? 0),
            carbs: Double(sourceMacros?.carbs ?? 0),
            protein: Double(sourceMacros?.protein ?? 0),
            fat: Double(sourceMacros?.fat ?? 0),
            fiber: Double(sourceMacros?.fiber ?? 0)
        )
    }
    
}

struct Macros: Codable, Hashable, Identifiable {
    var id = UUID()
    var kcal: Int = 0
    var carbs: Int = 0
    var protein: Int = 0
    var fat: Int = 0
    var fiber: Int = 0
}

struct Calories: Codable, Hashable, Identifiable {
    var id = UUID()
    var kcal: Double
    var carbs: Double
    var protein: Double
    var fat: Double
    var fiber: Double
    
    init(kcal: Double = 0, carbs: Double = 0, protein: Double = 0, fat: Double = 0, fiber: Double = 0){
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
    @DocumentID var documentID: String?
    var name: String?
    var products: [Product]?
    var kcal:Double
    var carbs: Double
    var protein: Double
    var fat: Double
    var fiber: Double
    
    init(id:UUID = UUID(), documentID:String? = nil, name: String? = nil, products:[Product]? = nil, kcal:Double = 0, carbs:Double = 0, protein:Double = 0, fat:Double = 0, fiber:Double = 0){
        self.id = id
        self.documentID = documentID
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
    var kcal: Double
    var carbs: Double
    var protein: Double
    var fat: Double
    var fiber: Double
    var unit: String
    var portions: [ProductPortion]
    var selectedProductDetails : SelectedProductDetails?
    
    init(id:UUID = UUID(), documentID:String? = "", name:String = "", kcal:Double = 0, carbs:Double = 0, protein:Double = 0, fat:Double = 0, fiber:Double = 0, unit:String = "Grammen", portions:[ProductPortion] = [ProductPortion(name: "Standaard", amount: 100)], selectedProductDetails: SelectedProductDetails? = nil){
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
    var kcal: Double
    var carbs: Double
    var protein: Double
    var fat: Double
    var fiber: Double
    var amount: Int
    
    init(id:UUID = UUID(), kcal:Double = 0, carbs:Double = 0, protein:Double = 0, fat:Double = 0, fiber:Double = 0, amount:Int = 0){
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

struct SlimProductList: Codable, Hashable, Identifiable{
    var id = UUID()
    var products: [SlimProduct]
    
    init(id:UUID = UUID(), products:[SlimProduct] = []){
        self.id = id
        self.products = products
    }
}

struct SlimProduct: Codable, Hashable{
    var id:UUID = UUID()
    var documentID: String
    var name: String
}
