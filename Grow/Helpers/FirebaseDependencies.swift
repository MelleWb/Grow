import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import FirebaseStorage

enum StartupDependencyError: Error, Equatable {
    case missingCurrentUserID
}

protocol SessionProviding {
    var currentUserID: String? { get }
}

protocol UserRepository {
    func fetchUser(uid: String, completion: @escaping (Result<User, Error>) -> Void)
}

protocol FamilyRepository {
    @discardableResult
    func observeFamilyMembers(userID: String, handler: @escaping (Result<[FamilyMember], Error>) -> Void) -> ListenerRegistration?
    @discardableResult
    func observeOutgoingFamilyInvites(userID: String, handler: @escaping (Result<[FamilyInvite], Error>) -> Void) -> ListenerRegistration?
    @discardableResult
    func observeIncomingFamilyInvites(userID: String, handler: @escaping (Result<[FamilyInvite], Error>) -> Void) -> ListenerRegistration?
    func sendFamilyInvite(email: String, completion: @escaping (Result<Void, Error>) -> Void)
    func respondToFamilyInvite(inviteID: String, accept: Bool, completion: @escaping (Result<Void, Error>) -> Void)
    func cancelFamilyInvite(inviteID: String, completion: @escaping (Result<Void, Error>) -> Void)
    func removeFamilyMember(otherUserID: String, completion: @escaping (Result<Void, Error>) -> Void)
}

protocol SchemaRepository {
    func fetchSchema(id: String, completion: @escaping (Result<Schema, Error>) -> Void)
}

protocol StoreManaging {
    var transactionDates: [Date] { get }
    func startObserving()
    func stopObserving()
    func getProducts()
}

protocol FoodDataLoading {
    @discardableResult
    func observeFoodDiary(userID: String, date: Date, handler: @escaping (Result<FoodDiary?, Error>) -> Void) -> ListenerRegistration?
    @discardableResult
    func observeMeals(handler: @escaping (Result<[Meal], Error>) -> Void) -> ListenerRegistration?
    @discardableResult
    func observeSlimProductList(handler: @escaping (Result<SlimProductList, Error>) -> Void) -> ListenerRegistration?
}

protocol TrainingDataLoading {
    @discardableResult
    func observeSchemas(handler: @escaping (Result<[Schema], Error>) -> Void) -> ListenerRegistration?
}

protocol StatisticsDataLoading {
    func fetchCurrentRoutineTrainingStatistics(userID: String, routineID: UUID, completion: @escaping (Result<TrainingStatistics?, Error>) -> Void)
    @discardableResult
    func observeRoutineTrainingStatistics(userID: String, routineID: UUID, handler: @escaping (Result<[TrainingStatistics], Error>) -> Void) -> ListenerRegistration?
    @discardableResult
    func observeTrainingHistory(userID: String, handler: @escaping (Result<[TrainingStatistics], Error>) -> Void) -> ListenerRegistration?
}

protocol FoodDataWriting {
    func copyMeal(userID: String, date: Date, meal: Meal, completion: @escaping (Result<Void, Error>) -> Void)
    func saveProduct(_ product: Product, slimProductList: SlimProductList, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteProduct(documentID: String, slimProductList: SlimProductList, completion: @escaping (Result<Void, Error>) -> Void)
    func saveDiary(userID: String, diary: FoodDiary, completion: @escaping (Result<Void, Error>) -> Void)
    func saveMeal(_ meal: Meal, completion: @escaping (Result<String, Error>) -> Void)
    func deleteMeal(documentID: String, completion: @escaping (Result<Void, Error>) -> Void)
    func shareMealWithFamily(otherUserID: String, sourceDate: Date, meal: Meal, completion: @escaping (Result<Void, Error>) -> Void)
}

protocol TrainingDataWriting {
    func fetchSchema(documentID: String, completion: @escaping (Result<Schema, Error>) -> Void)
    func createSchema(_ schema: Schema, completion: @escaping (Result<Void, Error>) -> Void)
    func updateSchema(_ schema: Schema, completion: @escaping (Result<Void, Error>) -> Void)
}

protocol StatisticsDataWriting {
    func saveTraining(userID: String, exerciseStatistics: [ExerciseStatistics], trainingStatistics: TrainingStatistics, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteTrainingHistory(userID: String, documentID: String, completion: @escaping (Result<Void, Error>) -> Void)
}

struct FirebaseSessionProvider: SessionProviding {
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
}

struct FirestoreUserRepository: UserRepository {
    func fetchUser(uid: String, completion: @escaping (Result<User, Error>) -> Void) {
        Firestore.firestore().collection("users").document(uid).getDocument { document, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let document, document.exists else {
                completion(.failure(FirebaseDependencyError.documentNotFound))
                return
            }

            do {
                completion(.success(try document.data(as: User.self)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

struct FirebaseFamilyRepository: FamilyRepository {
    private let functions = Functions.functions(region: "europe-west2")

    func observeFamilyMembers(userID: String, handler: @escaping (Result<[FamilyMember], Error>) -> Void) -> ListenerRegistration? {
        Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("familyMembers")
            .addSnapshotListener { snapshot, error in
                if let error {
                    handler(.failure(error))
                    return
                }

                let members = snapshot?.documents.compactMap { document in
                    try? document.data(as: FamilyMember.self)
                } ?? []

                handler(.success(members.sorted { lhs, rhs in
                    (lhs.linkedAt ?? .distantPast) > (rhs.linkedAt ?? .distantPast)
                }))
            }
    }

    func observeOutgoingFamilyInvites(userID: String, handler: @escaping (Result<[FamilyInvite], Error>) -> Void) -> ListenerRegistration? {
        Firestore.firestore()
            .collection("familyInvites")
            .whereField("fromUserID", isEqualTo: userID)
            .addSnapshotListener { snapshot, error in
                handleInviteSnapshot(snapshot: snapshot, error: error, handler: handler)
            }
    }

    func observeIncomingFamilyInvites(userID: String, handler: @escaping (Result<[FamilyInvite], Error>) -> Void) -> ListenerRegistration? {
        Firestore.firestore()
            .collection("familyInvites")
            .whereField("toUserID", isEqualTo: userID)
            .addSnapshotListener { snapshot, error in
                handleInviteSnapshot(snapshot: snapshot, error: error, handler: handler)
            }
    }

    func sendFamilyInvite(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        functions.httpsCallable("sendFamilyInvite").call(["email": email]) { _, error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func respondToFamilyInvite(inviteID: String, accept: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        functions.httpsCallable("respondToFamilyInvite").call([
            "inviteId": inviteID,
            "accept": accept
        ]) { _, error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func cancelFamilyInvite(inviteID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        functions.httpsCallable("cancelFamilyInvite").call([
            "inviteId": inviteID
        ]) { _, error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func removeFamilyMember(otherUserID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        functions.httpsCallable("removeFamilyMember").call([
            "otherUserId": otherUserID
        ]) { _, error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    private func handleInviteSnapshot(
        snapshot: QuerySnapshot?,
        error: Error?,
        handler: @escaping (Result<[FamilyInvite], Error>) -> Void
    ) {
        if let error {
            handler(.failure(error))
            return
        }

        let invites = snapshot?.documents.compactMap { document in
            try? document.data(as: FamilyInvite.self)
        } ?? []

        let pendingInvites = invites
            .filter { $0.status == .pending }
            .sorted { lhs, rhs in
                (lhs.createdAt ?? .distantPast) > (rhs.createdAt ?? .distantPast)
            }

        handler(.success(pendingInvites))
    }
}

struct FirestoreSchemaRepository: SchemaRepository {
    func fetchSchema(id: String, completion: @escaping (Result<Schema, Error>) -> Void) {
        Firestore.firestore().collection("schemas").document(id).getDocument { document, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let document, document.exists else {
                completion(.failure(FirebaseDependencyError.documentNotFound))
                return
            }

            do {
                var schema = try document.data(as: Schema.self)
                schema.docID = document.documentID
                completion(.success(schema))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

enum FirebaseDependencyError: Error {
    case documentNotFound
}

extension StoreManager: StoreManaging {}

struct FirestoreFoodDataLoader: FoodDataLoading {
    func observeFoodDiary(userID: String, date: Date, handler: @escaping (Result<FoodDiary?, Error>) -> Void) -> ListenerRegistration? {
        let docRef = Firestore.firestore().collection("users").document(userID).collection("foodDiary")
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let start = calendar.date(from: components) ?? date
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start

        return docRef
            .whereField("date", isGreaterThan: start)
            .whereField("date", isLessThan: end)
            .limit(to: 1)
            .addSnapshotListener { querySnapshot, error in
                if let error {
                    handler(.failure(error))
                    return
                }

                guard let document = querySnapshot?.documents.first else {
                    handler(.success(nil))
                    return
                }

                do {
                    handler(.success(try document.data(as: FoodDiary.self)))
                } catch {
                    handler(.failure(error))
                }
            }
    }

    func observeMeals(handler: @escaping (Result<[Meal], Error>) -> Void) -> ListenerRegistration? {
        Firestore.firestore().collection("meals").addSnapshotListener { querySnapshot, error in
            if let error {
                handler(.failure(error))
                return
            }

            guard let documents = querySnapshot?.documents else {
                handler(.success([]))
                return
            }

            let meals = documents.compactMap { document -> Meal? in
                try? document.data(as: Meal.self)
            }
            handler(.success(meals))
        }
    }

    func observeSlimProductList(handler: @escaping (Result<SlimProductList, Error>) -> Void) -> ListenerRegistration? {
        Firestore.firestore().collection("foodOverview").document("dA3UCyGYWDHRumopuAAg").addSnapshotListener { documentSnapshot, error in
            if let error {
                handler(.failure(error))
                return
            }

            guard let documentSnapshot else {
                handler(.success(SlimProductList()))
                return
            }

            do {
                handler(.success(try documentSnapshot.data(as: SlimProductList.self)))
            } catch {
                handler(.failure(error))
            }
        }
    }
}

struct FirestoreTrainingDataLoader: TrainingDataLoading {
    func observeSchemas(handler: @escaping (Result<[Schema], Error>) -> Void) -> ListenerRegistration? {
        Firestore.firestore().collection("schemas").addSnapshotListener { querySnapshot, error in
            if let error {
                handler(.failure(error))
                return
            }

            guard let documents = querySnapshot?.documents else {
                handler(.success([]))
                return
            }

            let schemas = documents.compactMap { document -> Schema? in
                guard var schema = try? document.data(as: Schema.self) else {
                    return nil
                }
                schema.docID = document.documentID
                return schema
            }
            handler(.success(schemas))
        }
    }
}

struct FirestoreStatisticsDataLoader: StatisticsDataLoading {
    func fetchCurrentRoutineTrainingStatistics(userID: String, routineID: UUID, completion: @escaping (Result<TrainingStatistics?, Error>) -> Void) {
        Firestore.firestore().collection("users").document(userID).collection("trainingStatistics")
            .whereField("routineID", isEqualTo: routineID.uuidString)
            .order(by: "trainingDate", descending: true)
            .limit(to: 1)
            .getDocuments { querySnapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                guard let document = querySnapshot?.documents.first else {
                    completion(.success(nil))
                    return
                }

                do {
                    completion(.success(try document.data(as: TrainingStatistics.self)))
                } catch {
                    completion(.failure(error))
                }
            }
    }

    func observeRoutineTrainingStatistics(userID: String, routineID: UUID, handler: @escaping (Result<[TrainingStatistics], Error>) -> Void) -> ListenerRegistration? {
        Firestore.firestore().collection("users").document(userID).collection("trainingStatistics")
            .whereField("routineID", isEqualTo: routineID.uuidString)
            .order(by: "trainingDate", descending: false)
            .limit(to: 10)
            .addSnapshotListener { querySnapshot, error in
                if let error {
                    handler(.failure(error))
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    handler(.success([]))
                    return
                }

                let statistics = documents.compactMap { document -> TrainingStatistics? in
                    try? document.data(as: TrainingStatistics.self)
                }
                handler(.success(statistics))
            }
    }

    func observeTrainingHistory(userID: String, handler: @escaping (Result<[TrainingStatistics], Error>) -> Void) -> ListenerRegistration? {
        Firestore.firestore().collection("users").document(userID).collection("trainingStatistics")
            .order(by: "trainingDate", descending: true)
            .limit(to: 10)
            .addSnapshotListener { querySnapshot, error in
                if let error {
                    handler(.failure(error))
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    handler(.success([]))
                    return
                }

                let statistics = documents.compactMap { document -> TrainingStatistics? in
                    try? document.data(as: TrainingStatistics.self)
                }
                handler(.success(statistics))
            }
    }
}

struct FirestoreFoodDataWriter: FoodDataWriting {
    private let functions = Functions.functions(region: "europe-west2")

    func copyMeal(userID: String, date: Date, meal: Meal, completion: @escaping (Result<Void, Error>) -> Void) {
        let docRef = Firestore.firestore().collection("users").document(userID).collection("foodDiary")
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let start = calendar.date(from: components) ?? date
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start

        docRef
            .whereField("date", isGreaterThan: start)
            .whereField("date", isLessThan: end)
            .limit(to: 1)
            .getDocuments { querySnapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                do {
                    if let document = querySnapshot?.documents.first {
                        var diary = try document.data(as: FoodDiary.self)
                        if diary.meals == nil {
                            diary.meals = [meal]
                        } else {
                            diary.meals?.append(meal)
                        }
                        try docRef.document(document.documentID).setData(from: diary, merge: true)
                    } else {
                        var diary = FoodDiary()
                        diary.meals = [meal]
                        diary.date = date
                        try docRef.document().setData(from: diary)
                    }

                    completion(.success(()))
                } catch {
                    completion(.failure(error))
                }
            }
    }

    func saveProduct(_ product: Product, slimProductList: SlimProductList, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        let prodRef = db.collection("foodProducts")
        let slimProdRef = db.collection("foodOverview").document("dA3UCyGYWDHRumopuAAg")
        let docRef = product.documentID.flatMap { !$0.isEmpty ? prodRef.document($0) : nil } ?? prodRef.document()

        do {
            try docRef.setData(from: product, merge: true)
            try slimProdRef.setData(from: slimProductList, merge: true)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func deleteProduct(documentID: String, slimProductList: SlimProductList, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        db.collection("foodProducts").document(documentID).delete { error in
            if let error {
                completion(.failure(error))
                return
            }

            do {
                let slimProdRef = db.collection("foodOverview").document("dA3UCyGYWDHRumopuAAg")
                try slimProdRef.setData(from: slimProductList, merge: true)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func saveDiary(userID: String, diary: FoodDiary, completion: @escaping (Result<Void, Error>) -> Void) {
        let diaryRef = Firestore.firestore().collection("users").document(userID).collection("foodDiary")

        if let diaryID = diary.id, diaryID.isEmpty == false {
            persistDiary(diary, in: diaryRef.document(diaryID), completion: completion)
            return
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: diary.date)
        let start = calendar.date(from: components) ?? diary.date
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start

        diaryRef
            .whereField("date", isGreaterThan: start)
            .whereField("date", isLessThan: end)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                if let existingDocument = snapshot?.documents.first {
                    persistDiary(diary, in: existingDocument.reference, completion: completion)
                    return
                }

                let documentRef = diaryRef.document(self.diaryDocumentID(for: start))
                persistDiary(diary, in: documentRef, completion: completion)
            }
    }

    func saveMeal(_ meal: Meal, completion: @escaping (Result<String, Error>) -> Void) {
        let mealRef = Firestore.firestore().collection("meals")
        let documentRef = meal.documentID.flatMap { !$0.isEmpty ? mealRef.document($0) : nil } ?? mealRef.document()

        do {
            try documentRef.setData(from: meal, merge: true)
            completion(.success(documentRef.documentID))
        } catch {
            completion(.failure(error))
        }
    }

    func deleteMeal(documentID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Firestore.firestore().collection("meals").document(documentID).delete { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func shareMealWithFamily(otherUserID: String, sourceDate: Date, meal: Meal, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let payload = try ShareableMealPayload(meal: meal).asDictionary()
            let isoDate = ISO8601DateFormatter().string(from: sourceDate)

            functions.httpsCallable("shareMealWithFamily").call([
                "otherUserId": otherUserID,
                "sourceDate": isoDate,
                "meal": payload
            ]) { _, error in
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    private func persistDiary(_ diary: FoodDiary, in documentRef: DocumentReference, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try documentRef.setData(from: diary, merge: true)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    private func diaryDocumentID(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private struct ShareableMealPayload: Encodable {
    let id: String
    let documentID: String?
    let userID: String?
    let name: String?
    let products: [ShareableProductPayload]?
    let recipe: ShareableMealRecipePayload?
    let kcal: Double
    let carbs: Double
    let protein: Double
    let fat: Double
    let fiber: Double

    init(meal: Meal) {
        id = meal.id.uuidString
        documentID = meal.documentID
        userID = meal.userID
        name = meal.name
        products = meal.products?.map(ShareableProductPayload.init)
        recipe = meal.recipe.map(ShareableMealRecipePayload.init)
        kcal = meal.kcal
        carbs = meal.carbs
        protein = meal.protein
        fat = meal.fat
        fiber = meal.fiber
    }

    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder.shareMealEncoder.encode(self)
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dictionary = object as? [String: Any] else {
            throw ShareMealEncodingError.invalidPayload
        }
        return dictionary
    }
}

private struct ShareableMealRecipePayload: Encodable {
    let sourceURL: String
    let sourceDomain: String
    let title: String
    let imageSourceURL: String?
    let imageStorageURL: String?
    let imageStoragePath: String?
    let sourceYieldText: String?
    let totalTimeText: String?
    let ingredients: [String]?
    let instructions: [String]
    let importedAt: Date

    init(recipe: MealRecipe) {
        sourceURL = recipe.sourceURL
        sourceDomain = recipe.sourceDomain
        title = recipe.title
        imageSourceURL = recipe.imageSourceURL
        imageStorageURL = recipe.imageStorageURL
        imageStoragePath = recipe.imageStoragePath
        sourceYieldText = recipe.sourceYieldText
        totalTimeText = recipe.totalTimeText
        ingredients = recipe.ingredients
        instructions = recipe.instructions
        importedAt = recipe.importedAt
    }
}

private struct ShareableProductPayload: Encodable {
    let id: String
    let documentID: String?
    let userID: String?
    let name: String
    let kcal: Double
    let carbs: Double
    let protein: Double
    let fat: Double
    let fiber: Double
    let unit: String
    let portions: [ShareableProductPortionPayload]
    let selectedProductDetails: ShareableSelectedProductDetailsPayload?

    init(product: Product) {
        id = product.id.uuidString
        documentID = product.documentID
        userID = product.userID
        name = product.name
        kcal = product.kcal
        carbs = product.carbs
        protein = product.protein
        fat = product.fat
        fiber = product.fiber
        unit = product.unit
        portions = product.portions.map(ShareableProductPortionPayload.init)
        selectedProductDetails = product.selectedProductDetails.map(ShareableSelectedProductDetailsPayload.init)
    }
}

private struct ShareableSelectedProductDetailsPayload: Encodable {
    let id: String
    let kcal: Double
    let carbs: Double
    let protein: Double
    let fat: Double
    let fiber: Double
    let amount: Int

    init(details: SelectedProductDetails) {
        id = details.id.uuidString
        kcal = details.kcal
        carbs = details.carbs
        protein = details.protein
        fat = details.fat
        fiber = details.fiber
        amount = details.amount
    }
}

private struct ShareableProductPortionPayload: Encodable {
    let id: String
    let name: String
    let amount: Int

    init(portion: ProductPortion) {
        id = portion.id.uuidString
        name = portion.name
        amount = portion.amount
    }
}

private enum ShareMealEncodingError: Error {
    case invalidPayload
}

private extension JSONEncoder {
    static var shareMealEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

struct FirestoreTrainingDataWriter: TrainingDataWriting {
    func fetchSchema(documentID: String, completion: @escaping (Result<Schema, Error>) -> Void) {
        Firestore.firestore().collection("schemas").document(documentID).getDocument { document, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let document else {
                completion(.failure(FirebaseDependencyError.documentNotFound))
                return
            }

            do {
                var schema = try document.data(as: Schema.self)
                schema.docID = document.documentID
                completion(.success(schema))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func createSchema(_ schema: Schema, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Firestore.firestore().collection("schemas").document().setData(from: schema, merge: true)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func updateSchema(_ schema: Schema, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let docID = schema.docID else {
            completion(.failure(FirebaseDependencyError.documentNotFound))
            return
        }

        do {
            try Firestore.firestore().collection("schemas").document(docID).setData(from: schema, merge: true)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}

struct FirestoreStatisticsDataWriter: StatisticsDataWriting {
    func saveTraining(userID: String, exerciseStatistics: [ExerciseStatistics], trainingStatistics: TrainingStatistics, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()

        do {
            for exercise in exerciseStatistics {
                try db.collection("users").document(userID).collection("exerciseStatistics").document().setData(from: exercise, merge: true)
            }

            try db.collection("users").document(userID).collection("trainingStatistics").document().setData(from: trainingStatistics, merge: true)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func deleteTrainingHistory(userID: String, documentID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Firestore.firestore().collection("users").document(userID).collection("trainingStatistics").document(documentID).delete { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
