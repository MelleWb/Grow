//
//  StatisticsModel.swift
//  Grow
//
//  Created by Swen Rolink on 09/08/2021.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

private extension KeyedDecodingContainer {
    func decodeUUIDIfPresent(forKey key: Key) -> UUID? {
        if let value = try? decodeIfPresent(UUID.self, forKey: key) {
            return value
        }
        
        if let stringValue = try? decodeIfPresent(String.self, forKey: key) {
            return UUID(uuidString: stringValue)
        }
        
        return nil
    }
}

class StatisticsDataModel: ObservableObject {
    
    @Published var exerciseStatistics = [ExerciseStatistics]()
    @Published var schemaStatistics = SchemaStatistics()
    @Published var maxWeight = ExerciseStatistics()
    @Published var estimatedWeights = [EstimatedWeights()]
    @Published var trainingStatistics = TrainingStatistics()
    @Published var trainingHistory = [TrainingStatistics()]
    
    var trainingHistoryListener: ListenerRegistration? = nil
    var trainingStatsListener: ListenerRegistration? = nil
    var exerciseDetailsListener: ListenerRegistration? = nil
    var user = User()
    private let sessionProvider: SessionProviding
    private let userRepository: UserRepository
    private let schemaRepository: SchemaRepository
    private let statisticsDataLoader: StatisticsDataLoading
    private let statisticsDataWriter: StatisticsDataWriting
    private let runStartupSideEffects: Bool
    
    init(
        sessionProvider: SessionProviding = FirebaseSessionProvider(),
        userRepository: UserRepository = FirestoreUserRepository(),
        schemaRepository: SchemaRepository = FirestoreSchemaRepository(),
        statisticsDataLoader: StatisticsDataLoading = FirestoreStatisticsDataLoader(),
        statisticsDataWriter: StatisticsDataWriting = FirestoreStatisticsDataWriter(),
        autostart: Bool = true,
        runStartupSideEffects: Bool = true
    ){
        self.sessionProvider = sessionProvider
        self.userRepository = userRepository
        self.schemaRepository = schemaRepository
        self.statisticsDataLoader = statisticsDataLoader
        self.statisticsDataWriter = statisticsDataWriter
        self.runStartupSideEffects = runStartupSideEffects

        guard autostart else {
            return
        }

        self.initiateStatistics()
    }
    
    func initiateStatistics(){
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

                self.exerciseStatistics = []
                self.trainingStatistics = TrainingStatistics()
                
                if self.trainingStatsListener != nil {
                    self.trainingStatsListener?.remove()
                }
                self.getStatisticsForCurrentSchema()
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func resetUser(user: User) {
        self.user = user
        
        //Remove the listener
        trainingStatsListener?.remove()
        trainingStatsListener = nil
        self.exerciseStatistics = []
        self.trainingStatistics = TrainingStatistics()
        
        //Initiate the schema stats again
        self.getStatisticsForCurrentSchema()
    }
    
    func calcEstimatedWeights(for exerciseName: String){
        self.fetchStatsForExercise(for: exerciseName)
    }
    
    func getEstimatedOneRepMax(given reps: Int, weight: Double) -> Double {
        let percentage:Double = self.getPercentageForReps(reps: reps)
        
        let roundedKGs = (Double(weight) / percentage)
        return roundedKGs
        
    }

    func getEstimatedWeightForReps(oneRepMax:Double, reps:Int) -> Double{
        
        let percentage:Double = self.getPercentageForReps(reps: reps)
        
        let roundedKGs = (Double(oneRepMax) * percentage)
        return roundedKGs
    }
    
    func getPercentageForReps(reps: Int) -> Double {
        
        var percentage: Double = 0

        switch reps {
        case 1:
            percentage = 1
        case 2:
            percentage = 0.97
        case 3:
            percentage = 0.94
        case 4:
            percentage = 0.92
        case 5:
            percentage = 0.89
        case 6:
            percentage = 0.86
        case 7:
            percentage = 0.83
        case 8:
            percentage = 0.81
        case 9:
            percentage = 0.78
        case 10:
            percentage = 0.75
        case 11:
            percentage = 0.73
        case 12:
            percentage = 0.71
        case 13:
            percentage = 0.70
        case 14:
            percentage = 0.68
        case 15:
            percentage = 0.67
        default:
            percentage = 0.60
        }
        return percentage
    }

    
    func fetchStatsForExercise(for exerciseName: String){
        guard let userID = sessionProvider.currentUserID else {
            self.exerciseStatistics = []
            self.maxWeight = ExerciseStatistics()
            self.estimatedWeights = []
            return
        }

        exerciseDetailsListener?.remove()

        let db = Firestore.firestore()

        exerciseDetailsListener = db.collection("users").document(userID).collection("exerciseStatistics")
            .whereField("exerciseName", isEqualTo: exerciseName)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    if let error = error {
                        print("No exercise statistics: \(error)")
                    }
                    self.exerciseStatistics = []
                    self.maxWeight = ExerciseStatistics()
                    self.estimatedWeights = []
                    return
                }

                self.exerciseStatistics = documents.compactMap { queryDocumentSnapshot in
                    let result = Result {
                        try queryDocumentSnapshot.data(as: ExerciseStatistics.self)
                    }

                    switch result {
                    case .success(let stats):
                        return stats
                    case .failure(let error):
                        print("error decoding exercise statistics: \(error)")
                        return nil
                    }
                }
                .sorted { lhs, rhs in
                    if lhs.date == rhs.date {
                        return lhs.set < rhs.set
                    }
                    return lhs.date < rhs.date
                }

                self.updateExerciseInsights()
            }
    }

    private func updateExerciseInsights() {
        estimatedWeights = []
        maxWeight = ExerciseStatistics()

        let completedSets = exerciseStatistics.filter {
            ($0.reps ?? 0) > 0 && ($0.weight ?? 0) > 0
        }

        guard let bestSet = completedSets.max(by: { lhs, rhs in
            let lhsOneRepMax = lhs.estimatedOneRepMax ?? self.getEstimatedOneRepMax(given: lhs.reps ?? 1, weight: lhs.weight ?? 1)
            let rhsOneRepMax = rhs.estimatedOneRepMax ?? self.getEstimatedOneRepMax(given: rhs.reps ?? 1, weight: rhs.weight ?? 1)

            if lhsOneRepMax == rhsOneRepMax {
                return (lhs.weight ?? 0) < (rhs.weight ?? 0)
            }

            return lhsOneRepMax < rhsOneRepMax
        }) else {
            return
        }

        maxWeight = bestSet

        let oneRepMax = bestSet.estimatedOneRepMax ?? self.getEstimatedOneRepMax(
            given: bestSet.reps ?? 1,
            weight: bestSet.weight ?? 1
        )

        estimatedWeights = (1...15).map { reps in
            let repsString = reps == 1 ? "1 rep" : "\(reps) reps"
            return EstimatedWeights(
                reps: reps,
                repsString: repsString,
                weight: self.getEstimatedWeightForReps(oneRepMax: oneRepMax, reps: reps)
            )
        }
    }
    
    func getRepsPlaceholder(for exercise: Exercise, for set:Int) -> Int{
        var value: Int = 0
        
        if let exerciseID = self.trainingStatistics.exerciceStatistics?.firstIndex(where: {$0.exerciseName == exercise.name && $0.set == set}){
            value = self.trainingStatistics.exerciceStatistics![exerciseID].reps ?? 0
        }
        return value
    }
    
    func getWeightPlaceholder(for exercise: Exercise, for set:Int) -> Double{
        var value: Double = 0
        
        if let exerciseID = self.trainingStatistics.exerciceStatistics?.firstIndex(where: {$0.exerciseName == exercise.name && $0.set == set}){
            value = self.trainingStatistics.exerciceStatistics![exerciseID].weight ?? 0
        }
        return value
    }
    
    func getTodaysRoutine() -> UUID? {
        let dayOfWeek: Int = self.getDayForWeekPlan()
        guard
            let weekPlan = self.user.weekPlan,
            weekPlan.indices.contains(dayOfWeek)
        else {
            return nil
        }

        return weekPlan[dayOfWeek].routine
    }
    
    func getDayForWeekPlan() -> Int{
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())
        
        if dayOfWeek == 1{
            return 6
        }
        else {
            return dayOfWeek - 2
        }
    }
    
    func getStatisticsForCurrentRoutine(){
        let dayOfWeek = self.getDayForWeekPlan()

        guard
            let userID = self.user.id,
            let routineID = UserDataModel.routineID(for: self.user, dayOfWeek: dayOfWeek)
        else {
            return
        }

        statisticsDataLoader.fetchCurrentRoutineTrainingStatistics(userID: userID, routineID: routineID) { result in
            switch result {
            case .success(let statistics):
                self.trainingStatistics = statistics ?? TrainingStatistics()
            case .failure(let error):
                print("error decoding schema: \(error)")
                self.trainingStatistics = TrainingStatistics()
            }
        }
    }
    
    func getStatisticsForCurrentSchema(){
        
        if self.schemaStatistics.routineStats == nil && self.user.schema != nil {
        var schema:Schema = Schema()
        schemaRepository.fetchSchema(id: self.user.schema!) { result in
            switch result {
            case .success(let loadedSchema):
                schema = loadedSchema
                
                //Get routines for current schema
                for routine in schema.routines {
                    
                    var routineStats: RoutineStatistics = RoutineStatistics(type: routine.type )

                    guard let userID = self.user.id else {
                        continue
                    }

                    self.trainingStatsListener = self.statisticsDataLoader.observeRoutineTrainingStatistics(userID: userID, routineID: routine.id) { result in
                        switch result {
                        case .success(let trainingStatistics):
                            routineStats.trainingStats = trainingStatistics
                            if self.schemaStatistics.routineStats != nil {
                                self.schemaStatistics.routineStats?.append(routineStats)
                            } else {
                                self.schemaStatistics.routineStats = [routineStats]
                            }
                            self.getSchemaStatisticsInPercentages()
                        case .failure(let error):
                            print("error decoding schema: \(error)")
                        }
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
        }
    }
    
    func loadTrainingHistory(){
        
        if let userID = self.user.id {
            trainingHistoryListener = statisticsDataLoader.observeTrainingHistory(userID: userID) { result in
                switch result {
                case .success(let history):
                    self.trainingHistory = history
                case .failure(let error):
                    print("error decoding schema: \(error)")
                    self.trainingHistory = []
                }
            }
        }
    }
    
    func removeTrainingHistory(for index: Int){
        let documentID = self.trainingHistory[index].documentID ?? ""

        guard let userID = sessionProvider.currentUserID else {
            return
        }

        statisticsDataWriter.deleteTrainingHistory(userID: userID, documentID: documentID) { result in
            if case .failure(let error) = result {
                print("Error removing document: \(error)")
            }
        }
    }
    
    func getSchemaStatisticsInPercentages(){
        
        if self.schemaStatistics.routineStats != nil {
            for routineStats in self.schemaStatistics.routineStats!{
                let routineStatsId = routineStats.id
                
                var volumeArray:[Double] = []
                
                for trainingStats in routineStats.trainingStats{
                    volumeArray.append(trainingStats.trainingVolume)
                }
                let highestVolumeTraining:Double = volumeArray.max() ?? 0
                
                //loop again and set the value
                for trainingStats in routineStats.trainingStats{
                    
                    if let routineStatsIndex = self.schemaStatistics.routineStats!.firstIndex(where: { $0.id ==  routineStatsId }){
                        if let trainingStatsIndex = self.schemaStatistics.routineStats![routineStatsIndex].trainingStats.firstIndex(where: { $0.id == trainingStats.id }){
                            self.schemaStatistics.routineStats![routineStatsIndex].trainingStats[trainingStatsIndex].volumePercentage = Float( self.schemaStatistics.routineStats![routineStatsIndex].trainingStats[trainingStatsIndex].trainingVolume / highestVolumeTraining)
                            }
                        }
                }
            }
        }
    }
    
    func isValidTraining(for routine: Routine) -> Bool{
        var countOfSets: Int = 0
        
        for superset in routine.superset {
            let sets:Int = superset.sets
            let exercises:Int = superset.exercises.count
            let calculation = sets * exercises
            countOfSets += calculation
            }
        
        if exerciseStatistics.count != countOfSets{
            return false
        } else {
            return true
        }
    }   
    
    func saveTraining(for user: String, for routineID: UUID) -> Bool{

        var volume:Double = 0
        let date = Date()
        var success: Bool = true
        
        //Calculate volume
        for stats in exerciseStatistics{
            
            volume += (Double(stats.reps ?? 0) * Double(stats.weight ?? 0))
            
            let estimatedOneRepMax:Double = self.getEstimatedOneRepMax(given: stats.reps ?? 1, weight: stats.weight ?? 1)
            
            if let index = self.exerciseStatistics.firstIndex(where: { $0.id ==  stats.id }){
                self.exerciseStatistics[index].estimatedOneRepMax = estimatedOneRepMax
                }
            
            }
        
        let trainingStatisticsObject: TrainingStatistics = TrainingStatistics(routineID: routineID, trainingDate: date, trainingVolume: volume, exerciceStatistics: exerciseStatistics)
        
        statisticsDataWriter.saveTraining(userID: user, exerciseStatistics: exerciseStatistics, trainingStatistics: trainingStatisticsObject) { result in
            if case .failure = result {
                success = false
            }
        }
        return success
    }
    
    func getRepsForSet(for exercise: Exercise, for set: Int) -> Int {
        if let index = self.exerciseStatistics.firstIndex(where: { $0.exerciseID ==  exercise.id && $0.set == set}) {
            return self.exerciseStatistics[index].reps ?? 0
        }
        return 0
    }
    
    func getWeightForSet(for exercise: Exercise, for set: Int) -> Double {
        if let index = self.exerciseStatistics.firstIndex(where: { $0.exerciseID ==  exercise.id && $0.set == set}) {
            return self.exerciseStatistics[index].weight ?? 0
        }
        return 0
    }
    
    func createUpdateReps(for exercise: Exercise, for set: Int, with reps: Int) {
        //check if self.exerciseStatistics is empty
        if self.exerciseStatistics.isEmpty {
            self.exerciseStatistics = [ExerciseStatistics(id: UUID(), documentID: nil, exerciseID: exercise.id, exerciseName: exercise.name, date: Date(), set: set, reps: reps, weight: 0)]
        } else {
            if let index = self.exerciseStatistics.firstIndex(where: { $0.exerciseID ==  exercise.id && $0.set == set}) {

                    let weight:Double = self.exerciseStatistics[index].weight ?? 0
                    self.exerciseStatistics[index] = ExerciseStatistics(id: UUID(), documentID: nil, exerciseID: exercise.id, exerciseName: exercise.name, date: Date(), set: set, reps: reps, weight: weight)

            } else {
                //Initialize the stat
                self.exerciseStatistics.append(ExerciseStatistics(id: UUID(), documentID: nil, exerciseID: exercise.id, exerciseName: exercise.name, date: Date(), set: set, reps: reps, weight: 0))
            }
        }
    }
    
    func createUpdateWeight(for exercise: Exercise, for set: Int, with weight: Double) {
        
        //check if self.exerciseStatistics is empty
        if self.exerciseStatistics.isEmpty {
            self.exerciseStatistics = [ExerciseStatistics(id: UUID(), documentID: nil, exerciseID: exercise.id, exerciseName: exercise.name, date: Date(), set: set, reps: 0, weight: weight)]
        } else {
            if let index = self.exerciseStatistics.firstIndex(where: { $0.exerciseID ==  exercise.id && $0.set == set}) {
                
                    //Update the stat
                    let reps:Int = self.exerciseStatistics[index].reps ?? 0
                    self.exerciseStatistics[index] = ExerciseStatistics(id: UUID(), documentID: nil, exerciseID: exercise.id, exerciseName: exercise.name, date: Date(), set: set, reps: reps, weight: weight)
            } else {
                //Initialize the stat
                self.exerciseStatistics.append(ExerciseStatistics(id: UUID(), documentID: nil, exerciseID: exercise.id, exerciseName: exercise.name, date: Date(), set: set, reps: 0, weight: weight))
            }
        }
    }
}

struct TrainingStatistics: Codable, Identifiable, Hashable {
    var id = UUID()
    var routineID: UUID
    @DocumentID var documentID: String?
    var trainingDate: Date
    var trainingVolume: Double
    var volumePercentage: Float?
    var exerciceStatistics: [ExerciseStatistics]?
    
    init(id: UUID = UUID(),
         routineID: UUID = UUID(),
         documentID: String? = nil,
         trainingDate: Date = Date(),
         trainingVolume: Double = 0,
         volumePercentage:Float? = 0,
         exerciceStatistics:[ExerciseStatistics]? = nil)
        {
        self.id = id
        self.routineID = routineID
        self.documentID = documentID
        self.trainingDate = trainingDate
        self.trainingVolume = trainingVolume
        self.volumePercentage = volumePercentage
        self.exerciceStatistics = exerciceStatistics
    }
}

struct ExerciseStatistics : Codable, Identifiable, Hashable {
    var id: UUID
    @DocumentID var documentID: String?
    var exerciseID: UUID
    var exerciseName: String
    var date: Date
    var set: Int
    var reps: Int?
    var weight: Double?
    var estimatedOneRepMax: Double?
    
    init(id: UUID = UUID(), documentID: String? = nil, exerciseID: UUID = UUID(), exerciseName:String = "", date:Date = DateHelper.from(year: 1970, month: 1, day: 1),set:Int = 0, reps:Int? = 0, weight:Double? = 0, estimatedOneRepMax:Double? = 0 ){
        self.id = id
        self.documentID = documentID
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.date = date
        self.set = set
        self.reps = reps
        self.weight = weight
        self.estimatedOneRepMax = estimatedOneRepMax
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case exerciseID
        case exerciseName
        case date
        case set
        case reps
        case weight
        case estimatedOneRepMax
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = container.decodeUUIDIfPresent(forKey: .id) ?? UUID()
        self.documentID = nil
        self.exerciseID = container.decodeUUIDIfPresent(forKey: .exerciseID) ?? UUID()
        self.exerciseName = try container.decodeIfPresent(String.self, forKey: .exerciseName) ?? ""
        self.date = try container.decodeIfPresent(Date.self, forKey: .date) ?? DateHelper.from(year: 1970, month: 1, day: 1)
        self.set = try container.decodeIfPresent(Int.self, forKey: .set) ?? 0
        self.reps = try container.decodeIfPresent(Int.self, forKey: .reps)
        self.weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        self.estimatedOneRepMax = try container.decodeIfPresent(Double.self, forKey: .estimatedOneRepMax)
    }
}

struct SchemaStatistics: Codable, Identifiable, Hashable {
    var id = UUID()
    var routineStats: [RoutineStatistics]?
    
    init(id:UUID = UUID(), routineStats: [RoutineStatistics]? = nil){
        self.id = id
        self.routineStats = routineStats
    }
}

struct RoutineStatistics: Codable, Identifiable, Hashable {
    var id = UUID()
    var type: String
    var trainingStats: [TrainingStatistics]
    
    init(id:UUID = UUID(), type:String = "", trainingStats:[TrainingStatistics] = [TrainingStatistics()]){
        self.id = id
        self.type = type
        self.trainingStats = trainingStats
    }
}

struct EstimatedWeights:Codable, Identifiable, Hashable {
    var id = UUID()
    var reps: Int
    var repsString: String
    var weight: Double
    
    init(id: UUID = UUID(), reps: Int =  0, repsString: String = "", weight:Double = 0){
        self.id = id
        self.reps = reps
        self.repsString = repsString
        self.weight = weight
    }
}
