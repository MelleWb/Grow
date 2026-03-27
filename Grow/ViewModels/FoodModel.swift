//
//  FoodModel.swift
//  Grow
//
//  Created by Swen Rolink on 27/07/2021.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage


class FoodDataModel: ObservableObject{
    
    @Published var date: Date = Date()
    
    @Published var foodDiary = FoodDiary()
    @Published var products = [Product()]
    @Published var savedMeals = [Meal()]
    
    @Published var slimProductList = SlimProductList()
    
    var user = User()
    var foodDiaryListener: ListenerRegistration? = nil
    var todaysFoodDiaryListener: ListenerRegistration? = nil
    var mealListener: ListenerRegistration? = nil
    var productListener: ListenerRegistration? = nil
    
    @Published var todaysDiary = FoodDiary()
    @Published var otherDaysIntake = [FoodDiary()]
    @Published var shareMealErrorMessage: String?
    @Published var shareMealSuccessMessage: String?
    private var fullSlimProductList = SlimProductList()
    private let sessionProvider: SessionProviding
    private let userRepository: UserRepository
    private let foodDataLoader: FoodDataLoading
    private let foodDataWriter: FoodDataWriting
    private let runStartupSideEffects: Bool
    
    private enum ErrorType : Error {
        case NullPointer
    }

    enum MealRecipeImportError: Error {
        case userNotAuthenticated
        case invalidImageData
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
        self.getTodaysFoodDiary()
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
                self.getTodaysFoodDiary()
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
            self.foodDiaryListener?.remove()
            
            //Now fetch results
            self.foodDiary = FoodDiary()
            self.setCaloriesForDiary()
            self.getFoodDiary()
            self.foodDiary = self.todaysDiary
        } else {
            //Remove listener first
            self.foodDiaryListener?.remove()
            
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

    func getTodaysFoodDiary() {
        guard let userID = sessionProvider.currentUserID else {
            return
        }

        todaysFoodDiaryListener?.remove()
        todaysFoodDiaryListener = foodDataLoader.observeFoodDiary(userID: userID, date: Date()) { result in
            switch result {
            case .success(let diary):
                self.todaysDiary = diary ?? FoodDiary()
            case .failure:
                print("error decoding schema...")
                self.todaysDiary = FoodDiary()
            }

            self.setCaloriesForDiary(for: \.todaysDiary, date: Date())
            self.updateUsersCalories(for: \.todaysDiary)
            WatchFoodSummarySync.shared.push(diary: self.todaysDiary)
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

    func shareMealWithFamily(meal: Meal, otherUserID: String, sourceDate: Date, completion: @escaping (Bool) -> Void = { _ in }) {
        foodDataWriter.shareMealWithFamily(otherUserID: otherUserID, sourceDate: sourceDate, meal: meal) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.shareMealErrorMessage = nil
                    self.shareMealSuccessMessage = "Maaltijd gedeeld."
                    completion(true)
                case .failure(let error):
                    self.shareMealSuccessMessage = nil
                    self.shareMealErrorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
    
    func createProduct(product: Product) -> Bool{
        var slimProductList = self.fullSlimProductList
        var slimProduct: SlimProduct?

        let documentID = (product.documentID?.isEmpty == false) ? product.documentID! : UUID().uuidString
        let ownerUserID = ownerUserIDForNewContent()

        if let slimProdIndex:Int = slimProductList.products.firstIndex(where: { $0.documentID == documentID }){
            slimProduct = slimProductList.products[slimProdIndex]
            slimProduct!.name = product.name
            if slimProduct?.userID == nil {
                slimProduct?.userID = ownerUserID
            }
            slimProductList.products.remove(at: slimProdIndex)
            slimProductList.products.append(slimProduct!)
        } else {
            slimProduct = SlimProduct(documentID: documentID, name: product.name, userID: ownerUserID)
            slimProductList.products.append(slimProduct!)
        }

        var productToSave = product
        productToSave.documentID = documentID
        if product.documentID?.isEmpty != false {
            productToSave.userID = ownerUserID
        }

        var success = true
        foodDataWriter.saveProduct(productToSave, slimProductList: slimProductList) { result in
            if case .failure(let error) = result {
                print(error)
                success = false
            } else {
                self.fullSlimProductList = slimProductList
                self.applyVisibleSlimProductFilter()
            }
        }
        return success
    }
    
    func deleteProduct(documentID: String){
        var slimProductList = self.fullSlimProductList

        if let slimProdIndex:Int = slimProductList.products.firstIndex(where: { $0.documentID == documentID }){
            slimProductList.products.remove(at: slimProdIndex)
        }

        foodDataWriter.deleteProduct(documentID: documentID, slimProductList: slimProductList) { result in
            if case .failure(let error) = result {
                print("Error removing document: \(error)")
            } else {
                self.fullSlimProductList = slimProductList
                self.applyVisibleSlimProductFilter()
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
                self.savedMeals = meals.filter { self.canAccessContent(ownerUserID: $0.userID) }
            case .failure:
                print("error decoding schema...")
                self.savedMeals = []
            }
        }
    }
    
    func saveMeal(for meal: Meal, completion: @escaping (Result<String, Error>) -> Void) {
        var mealToSave = meal
        if mealToSave.documentID?.isEmpty != false {
            mealToSave.userID = ownerUserIDForNewContent()
        }

        foodDataWriter.saveMeal(mealToSave) { result in
            switch result {
            case .success(let documentID):
                self.assignSavedMealDocumentID(documentID, to: mealToSave)
                completion(.success(documentID))
            case .failure(let error):
                print(error)
                completion(.failure(error))
            }
        }
    }

    func deleteSavedMeal(_ meal: Meal, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let documentID = meal.documentID, !documentID.isEmpty else {
            if let savedMealIndex = savedMeals.firstIndex(where: { $0.id == meal.id }) {
                savedMeals.remove(at: savedMealIndex)
            }
            completion(.success(()))
            return
        }

        foodDataWriter.deleteMeal(documentID: documentID) { result in
            switch result {
            case .success:
                if let savedMealIndex = self.savedMeals.firstIndex(where: { $0.documentID == documentID || $0.id == meal.id }) {
                    self.savedMeals.remove(at: savedMealIndex)
                }
                completion(.success(()))
            case .failure(let error):
                print(error)
                completion(.failure(error))
            }
        }
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
                self.fullSlimProductList = slimProductList
                self.applyVisibleSlimProductFilter()
            case .failure:
                print("error in parsing slim document list")
            }
        }
    }

    private func canAccessContent(ownerUserID: String?) -> Bool {
        guard let ownerUserID, !ownerUserID.isEmpty else {
            return true
        }

        return ownerUserID == sessionProvider.currentUserID
    }

    private func applyVisibleSlimProductFilter() {
        slimProductList = SlimProductList(
            id: fullSlimProductList.id,
            products: fullSlimProductList.products.filter { canAccessContent(ownerUserID: $0.userID) }
        )
    }

    private func ownerUserIDForNewContent() -> String? {
        if user.isAdmin {
            return nil
        }

        return user.id ?? sessionProvider.currentUserID
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
            let product: SlimProduct = SlimProduct(documentID: product.documentID ?? "", name: product.name, userID: product.userID)
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

    func updateMealRecipe(for meal: Meal, recipe: MealRecipe?) {
        guard let mealIndex = self.foodDiary.meals?.firstIndex(where: { $0.id == meal.id }) else {
            return
        }

        self.foodDiary.meals?[mealIndex].recipe = recipe
        self.updateMeal(for: meal)
    }

    func importMealRecipe(_ recipe: ParsedRecipe, for meal: Meal) async throws {
        let storedRecipe = try await importedMealRecipe(from: recipe)
        await MainActor.run {
            self.updateMealRecipe(for: meal, recipe: storedRecipe)
        }
    }

    func importedMealRecipe(from recipe: ParsedRecipe) async throws -> MealRecipe {
        try await storeMealRecipe(recipe)
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

    func currentMeal(for meal: Meal) -> Meal? {
        guard let mealIndex = getMealIndex(for: meal) else {
            return nil
        }

        return foodDiary.meals?[mealIndex]
    }

    func isSavedMeal(_ meal: Meal) -> Bool {
        guard let documentID = meal.documentID, !documentID.isEmpty else {
            return false
        }

        return savedMeals.contains { $0.documentID == documentID }
    }

    private func assignSavedMealDocumentID(_ documentID: String, to meal: Meal) {
        if let mealIndex = getMealIndex(for: meal) {
            foodDiary.meals?[mealIndex].documentID = documentID
        }

        if let savedMealIndex = savedMeals.firstIndex(where: { candidate in
            candidate.documentID == documentID || candidate.id == meal.id
        }) {
            savedMeals[savedMealIndex].documentID = documentID
        }
    }

    private func storeMealRecipe(_ recipe: ParsedRecipe) async throws -> MealRecipe {
        var storageURL: String?
        var storagePath: String?

        if let imageURL = recipe.imageURL {
            let imageData = try await fetchImageData(from: imageURL)
            let userID = try currentUserID()
            let path = "mealRecipes/\(userID)/\(UUID().uuidString).jpg"
            let reference = Storage.storage().reference().child(path)
            _ = try await putData(imageData, to: reference)
            storageURL = try await downloadURL(for: reference).absoluteString
            storagePath = path
        }

        return MealRecipe(
            sourceURL: recipe.sourceURL.absoluteString,
            sourceDomain: recipe.sourceURL.host ?? recipe.sourceURL.absoluteString,
            title: recipe.title,
            imageSourceURL: recipe.imageURL?.absoluteString,
            imageStorageURL: storageURL,
            imageStoragePath: storagePath,
            sourceYieldText: recipe.yieldText,
            totalTimeText: recipe.totalTimeText,
            ingredients: recipe.ingredients,
            instructions: recipe.instructions,
            importedAt: Date()
        )
    }

    private func currentUserID() throws -> String {
        guard let userID = sessionProvider.currentUserID else {
            throw MealRecipeImportError.userNotAuthenticated
        }

        return userID
    }

    private func fetchImageData(from url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard !data.isEmpty else {
            throw MealRecipeImportError.invalidImageData
        }
        return data
    }

    private func putData(_ data: Data, to reference: StorageReference) async throws -> StorageMetadata {
        try await withCheckedThrowingContinuation { continuation in
            reference.putData(data, metadata: nil) { metadata, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let metadata {
                    continuation.resume(returning: metadata)
                } else {
                    continuation.resume(throwing: MealRecipeImportError.invalidImageData)
                }
            }
        }
    }

    private func downloadURL(for reference: StorageReference) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            reference.downloadURL { url, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: MealRecipeImportError.invalidImageData)
                }
            }
        }
    }
    
    func updateUsersCalories(for keyPath: ReferenceWritableKeyPath<FoodDataModel, FoodDiary> = \.foodDiary){
        
        //Reset all values back to nil by created a clean object
        self[keyPath: keyPath].usersCalorieUsed = Calories()
        self[keyPath: keyPath].usersCalorieLeftOver = self[keyPath: keyPath].usersCalorieBudget
        self[keyPath: keyPath].usersCalorieUsedPercentage = CaloriesPercentages()
        
        if self[keyPath: keyPath].meals != nil {
            for meal in self[keyPath: keyPath].meals! {
                if meal.products != nil {
                    for product in meal.products! {
                        //First set the calories Used before we calculate the percentages
                        
                        self[keyPath: keyPath].usersCalorieUsed.kcal += product.selectedProductDetails?.kcal ?? 0
                        self[keyPath: keyPath].usersCalorieLeftOver.kcal = self[keyPath: keyPath].usersCalorieBudget.kcal - self[keyPath: keyPath].usersCalorieUsed.kcal
                        
                        self[keyPath: keyPath].usersCalorieUsed.carbs += product.selectedProductDetails?.carbs ?? 0
                        self[keyPath: keyPath].usersCalorieLeftOver.carbs = self[keyPath: keyPath].usersCalorieBudget.carbs - self[keyPath: keyPath].usersCalorieUsed.carbs
                        
                        self[keyPath: keyPath].usersCalorieUsed.protein += product.selectedProductDetails?.protein ?? 0
                        self[keyPath: keyPath].usersCalorieLeftOver.protein = self[keyPath: keyPath].usersCalorieBudget.protein - self[keyPath: keyPath].usersCalorieUsed.protein
                        
                        self[keyPath: keyPath].usersCalorieUsed.fat += product.selectedProductDetails?.fat ?? 0
                        self[keyPath: keyPath].usersCalorieLeftOver.fat = self[keyPath: keyPath].usersCalorieBudget.fat - self[keyPath: keyPath].usersCalorieUsed.fat
                        
                        self[keyPath: keyPath].usersCalorieUsed.fiber += product.selectedProductDetails?.fiber ?? 0
                        self[keyPath: keyPath].usersCalorieLeftOver.fiber = self[keyPath: keyPath].usersCalorieBudget.fiber - self[keyPath: keyPath].usersCalorieUsed.fiber
                    }
                }
            }
        }
        self.updateUsersCaloriePercentages(for: keyPath)
    }
    
    func updateUsersCaloriePercentages(for keyPath: ReferenceWritableKeyPath<FoodDataModel, FoodDiary> = \.foodDiary){
        self[keyPath: keyPath].usersCalorieUsedPercentage.kcal = Self.safePercentage(
            used: self[keyPath: keyPath].usersCalorieUsed.kcal,
            budget: self[keyPath: keyPath].usersCalorieBudget.kcal
        )

        self[keyPath: keyPath].usersCalorieUsedPercentage.carbs = Self.safePercentage(
            used: self[keyPath: keyPath].usersCalorieUsed.carbs,
            budget: self[keyPath: keyPath].usersCalorieBudget.carbs
        )

        self[keyPath: keyPath].usersCalorieUsedPercentage.protein = Self.safePercentage(
            used: self[keyPath: keyPath].usersCalorieUsed.protein,
            budget: self[keyPath: keyPath].usersCalorieBudget.protein
        )

        self[keyPath: keyPath].usersCalorieUsedPercentage.fat = Self.safePercentage(
            used: self[keyPath: keyPath].usersCalorieUsed.fat,
            budget: self[keyPath: keyPath].usersCalorieBudget.fat
        )

        self[keyPath: keyPath].usersCalorieUsedPercentage.fiber = Self.safePercentage(
            used: self[keyPath: keyPath].usersCalorieUsed.fiber,
            budget: self[keyPath: keyPath].usersCalorieBudget.fiber
        )
    }
    
    func setCaloriesForDiary(for keyPath: ReferenceWritableKeyPath<FoodDataModel, FoodDiary> = \.foodDiary, date: Date? = nil){

        let effectiveDate = date ?? self.date
        let dayOfWeek = self.getDayOfWeekAsNumber(date: effectiveDate)

        self[keyPath: keyPath].usersCalorieBudget = Self.calorieBudget(for: self.user, dayOfWeek: dayOfWeek)
        
        //Initiate the usersCalorieLeftOver and set it equal to the budget the first time
        self[keyPath: keyPath].usersCalorieLeftOver = self[keyPath: keyPath].usersCalorieBudget
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

    static func safePercentage(used: Double, budget: Double) -> Float {
        guard budget > 0 else {
            return 0
        }

        let value = Float(used / budget)
        return value.isFinite ? value : 0
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
    
    init(id:String? = nil,meals: [Meal]? = [Meal()], date: Date = Date(), usersCalorieBudget: Calories = Calories(), usersCalorieUsed: Calories = Calories(), usersCalorieLeftOver: Calories = Calories(), usersCalorieUsedPercentage: CaloriesPercentages = CaloriesPercentages()){
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
    var userID: String?
    var name: String?
    var products: [Product]?
    var recipe: MealRecipe?
    var kcal:Double
    var carbs: Double
    var protein: Double
    var fat: Double
    var fiber: Double
    
    init(id:UUID = UUID(), documentID:String? = nil, userID: String? = nil, name: String? = nil, products:[Product]? = nil, recipe: MealRecipe? = nil, kcal:Double = 0, carbs:Double = 0, protein:Double = 0, fat:Double = 0, fiber:Double = 0){
        self.id = id
        self.documentID = documentID
        self.userID = userID
        self.name = name
        self.products = products
        self.recipe = recipe
        self.kcal = kcal
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.fiber = fiber
    }
}

struct MealRecipe: Codable, Hashable {
    var sourceURL: String
    var sourceDomain: String
    var title: String
    var imageSourceURL: String?
    var imageStorageURL: String?
    var imageStoragePath: String?
    var sourceYieldText: String?
    var totalTimeText: String?
    var ingredients: [String]?
    var instructions: [String]
    var importedAt: Date

    enum CodingKeys: String, CodingKey {
        case sourceURL
        case sourceDomain
        case title
        case imageSourceURL
        case imageStorageURL
        case imageStoragePath
        case sourceYieldText
        case totalTimeText
        case ingredients
        case instructions
        case importedAt
    }

    init(
        sourceURL: String,
        sourceDomain: String,
        title: String,
        imageSourceURL: String? = nil,
        imageStorageURL: String? = nil,
        imageStoragePath: String? = nil,
        sourceYieldText: String? = nil,
        totalTimeText: String? = nil,
        ingredients: [String]? = nil,
        instructions: [String],
        importedAt: Date
    ) {
        self.sourceURL = sourceURL
        self.sourceDomain = sourceDomain
        self.title = title
        self.imageSourceURL = imageSourceURL
        self.imageStorageURL = imageStorageURL
        self.imageStoragePath = imageStoragePath
        self.sourceYieldText = sourceYieldText
        self.totalTimeText = totalTimeText
        self.ingredients = ingredients
        self.instructions = instructions
        self.importedAt = importedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        sourceURL = try container.decode(String.self, forKey: .sourceURL)
        sourceDomain = try container.decode(String.self, forKey: .sourceDomain)
        title = try container.decode(String.self, forKey: .title)
        imageSourceURL = try container.decodeIfPresent(String.self, forKey: .imageSourceURL)
        imageStorageURL = try container.decodeIfPresent(String.self, forKey: .imageStorageURL)
        imageStoragePath = try container.decodeIfPresent(String.self, forKey: .imageStoragePath)
        sourceYieldText = try container.decodeIfPresent(String.self, forKey: .sourceYieldText)
        totalTimeText = try container.decodeIfPresent(String.self, forKey: .totalTimeText)
        ingredients = try container.decodeIfPresent([String].self, forKey: .ingredients)
        instructions = try container.decode([String].self, forKey: .instructions)

        if let importedDate = try? container.decode(Date.self, forKey: .importedAt) {
            importedAt = importedDate
        } else if let importedString = try? container.decode(String.self, forKey: .importedAt) {
            if let parsedDate = ISO8601DateFormatter().date(from: importedString) {
                importedAt = parsedDate
            } else {
                importedAt = Date()
            }
        } else if let importedTimestamp = try? container.decode(Double.self, forKey: .importedAt) {
            importedAt = Date(timeIntervalSince1970: importedTimestamp)
        } else {
            importedAt = Date()
        }
    }
}

struct ParsedRecipe: Hashable {
    var sourceURL: URL
    var title: String
    var imageURL: URL?
    var yieldText: String?
    var servingsCount: Double?
    var totalTimeText: String?
    var ingredients: [String]
    var instructions: [String]
}

struct Product: Codable, Hashable, Identifiable{
    var id = UUID()
    @DocumentID var documentID: String?
    var userID: String?
    var name: String
    var kcal: Double
    var carbs: Double
    var protein: Double
    var fat: Double
    var fiber: Double
    var unit: String
    var portions: [ProductPortion]
    var selectedProductDetails : SelectedProductDetails?
    
    init(id:UUID = UUID(), documentID:String? = nil, userID: String? = nil, name:String = "", kcal:Double = 0, carbs:Double = 0, protein:Double = 0, fat:Double = 0, fiber:Double = 0, unit:String = "Grammen", portions:[ProductPortion] = [ProductPortion(name: "Standaard", amount: 100)], selectedProductDetails: SelectedProductDetails? = nil){
        self.id = id
        self.documentID = documentID
        self.userID = userID
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
    var userID: String?
}
