import Foundation
import FirebaseFirestore
import Testing
@testable import Grow

private struct SessionProviderStub: SessionProviding {
    var currentUserID: String?
}

private final class UserRepositorySpy: UserRepository {
    var fetchedUIDs = [String]()
    var result: Result<User, Error>

    init(result: Result<User, Error>) {
        self.result = result
    }

    func fetchUser(uid: String, completion: @escaping (Result<User, Error>) -> Void) {
        fetchedUIDs.append(uid)
        completion(result)
    }
}

private final class SchemaRepositorySpy: SchemaRepository {
    var fetchedIDs = [String]()
    var result: Result<Schema, Error>

    init(result: Result<Schema, Error> = .success(Schema())) {
        self.result = result
    }

    func fetchSchema(id: String, completion: @escaping (Result<Schema, Error>) -> Void) {
        fetchedIDs.append(id)
        completion(result)
    }
}

private final class StoreManagerSpy: StoreManaging {
    var transactionDates = [Date]()
    var startObservingCallCount = 0
    var stopObservingCallCount = 0
    var getProductsCallCount = 0

    func startObserving() {
        startObservingCallCount += 1
    }

    func stopObserving() {
        stopObservingCallCount += 1
    }

    func getProducts() {
        getProductsCallCount += 1
    }
}

private final class FoodDataLoaderSpy: FoodDataLoading {
    var observedFoodDiaryRequests = [(userID: String, date: Date)]()
    var observeMealsCallCount = 0
    var observeSlimProductListCallCount = 0
    var foodDiaryResult: Result<FoodDiary?, Error> = .success(nil)
    var mealsResult: Result<[Meal], Error> = .success([])
    var slimProductListResult: Result<SlimProductList, Error> = .success(SlimProductList())

    func observeFoodDiary(userID: String, date: Date, handler: @escaping (Result<FoodDiary?, Error>) -> Void) -> ListenerRegistration? {
        observedFoodDiaryRequests.append((userID, date))
        handler(foodDiaryResult)
        return nil
    }

    func observeMeals(handler: @escaping (Result<[Meal], Error>) -> Void) -> ListenerRegistration? {
        observeMealsCallCount += 1
        handler(mealsResult)
        return nil
    }

    func observeSlimProductList(handler: @escaping (Result<SlimProductList, Error>) -> Void) -> ListenerRegistration? {
        observeSlimProductListCallCount += 1
        handler(slimProductListResult)
        return nil
    }
}

private final class TrainingDataLoaderSpy: TrainingDataLoading {
    var observeSchemasCallCount = 0
    var schemasResult: Result<[Schema], Error> = .success([])

    func observeSchemas(handler: @escaping (Result<[Schema], Error>) -> Void) -> ListenerRegistration? {
        observeSchemasCallCount += 1
        handler(schemasResult)
        return nil
    }
}

private final class StatisticsDataLoaderSpy: StatisticsDataLoading {
    var fetchedRoutineRequests = [(userID: String, routineID: UUID)]()
    var observedRoutineRequests = [(userID: String, routineID: UUID)]()
    var observedTrainingHistoryUserIDs = [String]()
    var currentRoutineResult: Result<TrainingStatistics?, Error> = .success(nil)
    var routineStatisticsResult: Result<[TrainingStatistics], Error> = .success([])
    var trainingHistoryResult: Result<[TrainingStatistics], Error> = .success([])

    func fetchCurrentRoutineTrainingStatistics(userID: String, routineID: UUID, completion: @escaping (Result<TrainingStatistics?, Error>) -> Void) {
        fetchedRoutineRequests.append((userID, routineID))
        completion(currentRoutineResult)
    }

    func observeRoutineTrainingStatistics(userID: String, routineID: UUID, handler: @escaping (Result<[TrainingStatistics], Error>) -> Void) -> ListenerRegistration? {
        observedRoutineRequests.append((userID, routineID))
        handler(routineStatisticsResult)
        return nil
    }

    func observeTrainingHistory(userID: String, handler: @escaping (Result<[TrainingStatistics], Error>) -> Void) -> ListenerRegistration? {
        observedTrainingHistoryUserIDs.append(userID)
        handler(trainingHistoryResult)
        return nil
    }
}

private final class FoodDataWriterSpy: FoodDataWriting {
    var copiedMeals = [(userID: String, date: Date, meal: Meal)]()
    var savedProducts = [(product: Product, slimProductList: SlimProductList)]()
    var deletedProducts = [(documentID: String, slimProductList: SlimProductList)]()
    var savedDiaries = [(userID: String, diary: FoodDiary)]()
    var savedMeals = [Meal]()

    func copyMeal(userID: String, date: Date, meal: Meal, completion: @escaping (Result<Void, Error>) -> Void) {
        copiedMeals.append((userID, date, meal))
        completion(.success(()))
    }

    func saveProduct(_ product: Product, slimProductList: SlimProductList, completion: @escaping (Result<Void, Error>) -> Void) {
        savedProducts.append((product, slimProductList))
        completion(.success(()))
    }

    func deleteProduct(documentID: String, slimProductList: SlimProductList, completion: @escaping (Result<Void, Error>) -> Void) {
        deletedProducts.append((documentID, slimProductList))
        completion(.success(()))
    }

    func saveDiary(userID: String, diary: FoodDiary, completion: @escaping (Result<Void, Error>) -> Void) {
        savedDiaries.append((userID, diary))
        completion(.success(()))
    }

    func saveMeal(_ meal: Meal, completion: @escaping (Result<Void, Error>) -> Void) {
        savedMeals.append(meal)
        completion(.success(()))
    }
}

private final class TrainingDataWriterSpy: TrainingDataWriting {
    var fetchedSchemaIDs = [String]()
    var createdSchemas = [Schema]()
    var updatedSchemas = [Schema]()
    var fetchedSchemaResult: Result<Schema, Error> = .success(Schema())

    func fetchSchema(documentID: String, completion: @escaping (Result<Schema, Error>) -> Void) {
        fetchedSchemaIDs.append(documentID)
        completion(fetchedSchemaResult)
    }

    func createSchema(_ schema: Schema, completion: @escaping (Result<Void, Error>) -> Void) {
        createdSchemas.append(schema)
        completion(.success(()))
    }

    func updateSchema(_ schema: Schema, completion: @escaping (Result<Void, Error>) -> Void) {
        updatedSchemas.append(schema)
        completion(.success(()))
    }
}

private final class StatisticsDataWriterSpy: StatisticsDataWriting {
    var savedTrainings = [(userID: String, exerciseStatistics: [ExerciseStatistics], trainingStatistics: TrainingStatistics)]()
    var deletedTrainingHistory = [(userID: String, documentID: String)]()

    func saveTraining(userID: String, exerciseStatistics: [ExerciseStatistics], trainingStatistics: TrainingStatistics, completion: @escaping (Result<Void, Error>) -> Void) {
        savedTrainings.append((userID, exerciseStatistics, trainingStatistics))
        completion(.success(()))
    }

    func deleteTrainingHistory(userID: String, documentID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        deletedTrainingHistory.append((userID, documentID))
        completion(.success(()))
    }
}

private enum StartupTestError: Error {
    case failed
}

struct StartupIsolationTests {
    @Test
    func userDataModelStartupSkipsFetchWithoutCurrentUserID() {
        let repository = UserRepositorySpy(result: .failure(StartupTestError.failed))
        let schemaRepository = SchemaRepositorySpy()
        let storeManager = StoreManagerSpy()
        let model = UserDataModel(
            sessionProvider: SessionProviderStub(currentUserID: nil),
            userRepository: repository,
            schemaRepository: schemaRepository,
            storeManager: storeManager,
            autostart: true,
            runStartupSideEffects: false
        )

        #expect(repository.fetchedUIDs.isEmpty)
        #expect(schemaRepository.fetchedIDs.isEmpty)
        #expect(storeManager.startObservingCallCount == 0)
        #expect(storeManager.getProductsCallCount == 0)
        #expect(model.queryRunning == false)
    }

    @Test
    func foodDataModelStartupLoadsUserFromInjectedRepository() {
        var user = User()
        user.firstName = "Swen"
        user.restCalories = Macros(kcal: 2000, carbs: 200, protein: 160, fat: 60, fiber: 25)
        let foodDataLoader = FoodDataLoaderSpy()
        var foodDiary = FoodDiary()
        foodDiary.id = "diary-1"
        foodDataLoader.foodDiaryResult = .success(foodDiary)
        foodDataLoader.mealsResult = .success([Meal(name: "Lunch")])
        foodDataLoader.slimProductListResult = .success(SlimProductList(products: [SlimProduct(documentID: "prod-1", name: "Chicken")]))

        let repository = UserRepositorySpy(result: .success(user))
        let model = FoodDataModel(
            sessionProvider: SessionProviderStub(currentUserID: "user-123"),
            userRepository: repository,
            foodDataLoader: foodDataLoader,
            autostart: true,
            runStartupSideEffects: true
        )

        #expect(repository.fetchedUIDs == ["user-123"])
        #expect(model.user.firstName == "Swen")
        #expect(foodDataLoader.observedFoodDiaryRequests.count == 1)
        #expect(foodDataLoader.observeMealsCallCount == 1)
        #expect(foodDataLoader.observeSlimProductListCallCount == 1)
        #expect(model.foodDiary.id == "diary-1")
        #expect(model.savedMeals.count == 1)
        #expect(model.slimProductList.products.count == 1)
    }

    @Test
    func foodDataModelWritesUseInjectedWriter() {
        let writer = FoodDataWriterSpy()
        let model = FoodDataModel(
            sessionProvider: SessionProviderStub(currentUserID: "user-123"),
            userRepository: UserRepositorySpy(result: .failure(StartupTestError.failed)),
            foodDataLoader: FoodDataLoaderSpy(),
            foodDataWriter: writer,
            autostart: false,
            runStartupSideEffects: false
        )
        model.slimProductList = SlimProductList(products: [])
        model.foodDiary = FoodDiary(id: "diary-1", meals: nil, date: Date())
        model.date = Date()

        _ = model.createProduct(product: Product(name: "Chicken"))
        model.copyMeal(meal: Meal(name: "Lunch"))
        model.saveDiary()
        _ = model.saveMeal(for: Meal(name: "Dinner"))

        #expect(writer.savedProducts.count == 1)
        #expect(writer.copiedMeals.count == 1)
        #expect(writer.savedDiaries.count == 1)
        #expect(writer.savedMeals.count == 1)
    }

    @Test
    func trainingDataModelStartupLoadsUserAndFetchedSchemasFromInjectedDependencies() {
        var user = User()
        user.firstName = "Swen"

        let repository = UserRepositorySpy(result: .success(user))
        let schemaRepository = SchemaRepositorySpy()
        let trainingDataLoader = TrainingDataLoaderSpy()
        trainingDataLoader.schemasResult = .success([Schema(name: "Push Pull Legs")])
        let model = TrainingDataModel(
            sessionProvider: SessionProviderStub(currentUserID: "user-123"),
            userRepository: repository,
            schemaRepository: schemaRepository,
            trainingDataLoader: trainingDataLoader,
            autostart: true,
            runStartupSideEffects: true
        )

        #expect(repository.fetchedUIDs == ["user-123"])
        #expect(schemaRepository.fetchedIDs.isEmpty)
        #expect(trainingDataLoader.observeSchemasCallCount == 1)
        #expect(model.user.firstName == "Swen")
        #expect(model.fetchedSchemas.count == 1)
    }

    @Test
    func trainingDataModelWritesUseInjectedWriter() {
        let writer = TrainingDataWriterSpy()
        writer.fetchedSchemaResult = .success(Schema(name: "Fetched"))
        let model = TrainingDataModel(
            sessionProvider: SessionProviderStub(currentUserID: "user-123"),
            userRepository: UserRepositorySpy(result: .failure(StartupTestError.failed)),
            schemaRepository: SchemaRepositorySpy(),
            trainingDataLoader: TrainingDataLoaderSpy(),
            trainingDataWriter: writer,
            autostart: false,
            runStartupSideEffects: false
        )

        _ = model.createTraining(schema: Schema(name: "New Schema"))
        model.updateTraining(schema: Schema(docID: "schema-1", name: "Updated Schema"))
        model.getTrainingSchema(for: "schema-2")

        #expect(writer.createdSchemas.count == 1)
        #expect(writer.updatedSchemas.count == 1)
        #expect(writer.fetchedSchemaIDs == ["schema-2"])
        #expect(model.schema.name == "Fetched")
    }

    @Test
    func statisticsDataModelStartupLoadsStatisticsFromInjectedDependencies() {
        var user = User()
        user.firstName = "Swen"
        user.schema = "schema-123"
        user.id = "user-123"
        let routineID = UUID()
        user.weekPlan = [DayPlan(trainingType: "Push", routine: routineID, isTrainingDay: true)]

        let repository = UserRepositorySpy(result: .success(user))
        let schemaRepository = SchemaRepositorySpy(result: .success(Schema(name: "Push", routines: [Routine(type: "Push")])))
        let statisticsLoader = StatisticsDataLoaderSpy()
        statisticsLoader.currentRoutineResult = .success(TrainingStatistics(routineID: routineID, trainingDate: Date(), trainingVolume: 123))
        statisticsLoader.routineStatisticsResult = .success([TrainingStatistics(routineID: routineID, trainingDate: Date(), trainingVolume: 80)])
        let model = StatisticsDataModel(
            sessionProvider: SessionProviderStub(currentUserID: "user-123"),
            userRepository: repository,
            schemaRepository: schemaRepository,
            statisticsDataLoader: statisticsLoader,
            autostart: true,
            runStartupSideEffects: true
        )

        #expect(repository.fetchedUIDs == ["user-123"])
        #expect(schemaRepository.fetchedIDs == ["schema-123"])
        #expect(statisticsLoader.fetchedRoutineRequests.count == 1)
        #expect(statisticsLoader.observedRoutineRequests.count == 1)
        #expect(model.user.firstName == "Swen")
        #expect(model.trainingStatistics.trainingVolume == 123)
    }

    @Test
    func statisticsDataModelWritesUseInjectedWriter() {
        let writer = StatisticsDataWriterSpy()
        let model = StatisticsDataModel(
            sessionProvider: SessionProviderStub(currentUserID: "user-123"),
            userRepository: UserRepositorySpy(result: .failure(StartupTestError.failed)),
            schemaRepository: SchemaRepositorySpy(),
            statisticsDataLoader: StatisticsDataLoaderSpy(),
            statisticsDataWriter: writer,
            autostart: false,
            runStartupSideEffects: false
        )
        model.exerciseStatistics = [
            ExerciseStatistics(exerciseID: UUID(), exerciseName: "Bench", date: Date(), set: 1, reps: 8, weight: 100)
        ]
        model.trainingHistory = [
            TrainingStatistics(documentID: "training-1")
        ]

        _ = model.saveTraining(for: "user-123", for: UUID())
        model.removeTrainingHistory(for: 0)

        #expect(writer.savedTrainings.count == 1)
        #expect(writer.deletedTrainingHistory.count == 1)
        #expect(writer.deletedTrainingHistory.first?.userID == "user-123")
        #expect(writer.deletedTrainingHistory.first?.documentID == "training-1")
    }
}
