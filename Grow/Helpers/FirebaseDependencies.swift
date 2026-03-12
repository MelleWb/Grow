import Foundation
import FirebaseAuth
import FirebaseFirestore
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
    func saveMeal(_ meal: Meal, completion: @escaping (Result<Void, Error>) -> Void)
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
        let documentRef = diary.id.flatMap { !$0.isEmpty ? diaryRef.document($0) : nil } ?? diaryRef.document()

        do {
            try documentRef.setData(from: diary, merge: true)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func saveMeal(_ meal: Meal, completion: @escaping (Result<Void, Error>) -> Void) {
        let mealRef = Firestore.firestore().collection("meals")
        let documentRef = meal.documentID.flatMap { !$0.isEmpty ? mealRef.document($0) : nil } ?? mealRef.document()

        do {
            try documentRef.setData(from: meal, merge: true)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
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
