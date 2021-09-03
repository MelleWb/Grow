//
//  StatisticsModel.swift
//  Grow
//
//  Created by Swen Rolink on 09/08/2021.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

class StatisticsDataModel: ObservableObject {
    
    @Published var exerciseStatistics = [ExerciseStatistics]()
    @Published var schemaStatistics = SchemaStatistics()
    @Published var maxWeight = ExerciseStatistics()
    @Published var estimatedWeights = [EstimatedWeights()]
    @Published var trainingStatistics = TrainingStatistics()
    @Published var trainingHistory = [TrainingStatistics()]
    
    var trainingHistoryListener: ListenerRegistration? = nil
    var trainingStatsListener: ListenerRegistration? = nil
    var user = User()
    
    init(){
        self.initiateStatistics()
    }
    
    func initiateStatistics(){
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        let docRef = db.collection("users").document(Auth.auth().currentUser!.uid)

        docRef.getDocument(source: .cache) { (document, error) in
          if let document = document {
            do{
                self.user = try document.data(as: User.self)!
                self.getStatisticsForCurrentRoutine()
                
                if self.trainingStatsListener != nil {
                    self.trainingStatsListener?.remove()
                }
                self.getStatisticsForCurrentSchema()
                self.loadTrainingHistory()
            }
            catch {
              print(error)
            }
          } else {
            print("Document does not exist in cache")
          }
        }
    }
    
    func resetUser(user: User) {
        self.user = user
        
        //Remove the listener
        trainingStatsListener?.remove()
        
        //Initiate the stats again
        self.getStatisticsForCurrentRoutine()
        self.getStatisticsForCurrentSchema()
    }
    
    func calcEstimatedWeights(for exerciseName: String){
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        db.collection("users").document(Auth.auth().currentUser!.uid).collection("exerciseStatistics")
        .whereField("exerciseName", isEqualTo: exerciseName).order(by: "weight", descending: true).limit(to: 1).addSnapshotListener { (queryDocumentSnapshot, error) in

                guard let documents = queryDocumentSnapshot?.documents else {
                        print("No documents")
                    return
                }
                
            let exerciseStats: [ExerciseStatistics] = documents.map { (queryDocumentSnapshot) -> ExerciseStatistics in

                    let result = Result {
                        try queryDocumentSnapshot.data(as: ExerciseStatistics.self)
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
                    return ExerciseStatistics(id: UUID(), documentID: "", exerciseID: UUID(), exerciseName: "", date: DateHelper.from(year: 1970, month: 1, day: 1), set: 0, reps: 0, weight: 0)
                }
            if exerciseStats.count > 0 {
                
            self.maxWeight = exerciseStats[0]
            
            let oneRepMax:Double = self.getEstimatedOneRepMax(given: self.maxWeight.reps ?? 1, weight: Double(self.maxWeight.weight ?? 1))
            
            for i in 1...15 {
                let weight: Double = self.getEstimatedWeightForReps(oneRepMax: oneRepMax, reps: i)
                var repString = ""
                
                if i == 1 {
                    repString = "1 rep"
                }
                else {
                    repString = "\(i) reps"
                }
                
                if self.estimatedWeights[0].repsString == "" {
                    self.estimatedWeights = [EstimatedWeights(reps: i, repsString: repString, weight: weight)]
                } else {
                    self.estimatedWeights.append(EstimatedWeights(reps: i, repsString: repString, weight: weight))
                }
            
                }
            }
        }
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
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        
    db.collection("users").document(Auth.auth().currentUser!.uid).collection("exerciseStatistics")
        .whereField("exerciseName", isEqualTo: exerciseName).order(by: "estimatedOneRepMax", descending: true).limit(to: 1).addSnapshotListener { (querySnapshot, error) in

                guard let documents = querySnapshot?.documents else {
                        print("No documents")
                    return
                }
                
                self.exerciseStatistics = documents.map { (queryDocumentSnapshot) -> ExerciseStatistics in
                    
                    let result = Result {
                        try queryDocumentSnapshot.data(as: ExerciseStatistics.self)
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
                    return ExerciseStatistics(id: UUID(), documentID: "", exerciseID: UUID(), exerciseName: "", date: DateHelper.from(year: 1970, month: 1, day: 1), set: 0, reps: 0, weight: 0)
                }
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
    
    func getStatisticsForCurrentRoutine(){
        
        if self.user.id != "" && self.user.workoutOfTheDay != nil && self.user.workoutOfTheDay?.uuidString != ""{
        
            let routine:String = self.user.workoutOfTheDay!.uuidString
                
            let settings = FirestoreSettings()
            settings.isPersistenceEnabled = true
            let db = Firestore.firestore()
        
        
            db.collection("users").document(self.user.id!).collection("trainingStatistics")
                .whereField("routineID", isEqualTo: routine).order(by: "trainingDate", descending: true).limit(to: 1).getDocuments(completion: { (querySnapshot, error) in

                guard let documents = querySnapshot?.documents else {
                        print("No documents")
                    return
                }
                
            let _ = documents.map { (queryDocumentSnapshot) -> TrainingStatistics in
                    
                    let result = Result {
                        try queryDocumentSnapshot.data(as: TrainingStatistics.self)
                    }
                    switch result {
                    case .success(let stats):
                        if let stats = stats {
                            self.trainingStatistics = stats
                            return stats
                        }
                        else {
                            print ("Document does not exists")
                        }
                    case .failure(let error):
                        print("error decoding schema: \(error)")
                    }
                    return TrainingStatistics()
                }
            })
        }
    }
    
    func getStatisticsForCurrentSchema(){
        
        if self.schemaStatistics.routineStats == nil {
        var schema:Schema = Schema()
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
            let docRef = db.collection("schemas").document(self.user.schema!)
        
        docRef.getDocument { document, error in
          if (error as NSError?) != nil {
              print("Error getting document: \(error?.localizedDescription ?? "Unknown error")")
          }
          else {
            if let document = document {
              do {
                schema = try document.data(as: Schema.self)!
                
                //Get routines for current schema
                for routine in schema.routines {
                    
                    var routineStats: RoutineStatistics = RoutineStatistics(type: routine.type ?? "")
                    
                    let routineString:String = routine.id.uuidString
                    
                    self.trainingStatsListener = db.collection("users").document(Auth.auth().currentUser!.uid).collection("trainingStatistics")
                        .whereField("routineID", isEqualTo: routineString).order(by: "trainingDate", descending: true).limit(to: 10).addSnapshotListener { (querySnapshot, error) in
                            
                            guard let documents = querySnapshot?.documents else {
                                print("No documents")
                                return
                            }
                            
                            routineStats.trainingStats = documents.map { (queryDocumentSnapshot) -> TrainingStatistics in
                                
                                let result = Result {
                                    try queryDocumentSnapshot.data(as: TrainingStatistics.self)
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
                                return TrainingStatistics(routineID: UUID(), trainingDate: Date(), trainingVolume: 0)
                            }
                            if self.schemaStatistics.routineStats != nil {
                                self.schemaStatistics.routineStats?.append(routineStats)
                                } else {
                                    self.schemaStatistics.routineStats = [routineStats]
                                }
                            //Calculate the percentages now
                            self.getSchemaStatisticsInPercentages()
                        }
                }
                
              }
              catch {
                print(error)
              }
            }
          }
        }
        }
    }
    
    func loadTrainingHistory(){
        
        if self.user.id != nil {
        
            let settings = FirestoreSettings()
            settings.isPersistenceEnabled = true
            let db = Firestore.firestore()
            
            trainingHistoryListener = db.collection("users").document(self.user.id!).collection("trainingStatistics").order(by: "trainingDate", descending: true).addSnapshotListener { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("No documents")
                    return
                }
                
                self.trainingHistory = documents.map { (queryDocumentSnapshot) -> TrainingStatistics in
                    
                    let result = Result {
                        try queryDocumentSnapshot.data(as: TrainingStatistics.self)
                    }
                    switch result {
                    case .success(let history):
                        if let history = history {
                            return history
                        }
                        else {
                            print ("Document does not exists")
                        }
                    case .failure(let error):
                        print("error decoding schema: \(error)")
                    }
                    return TrainingStatistics()
                }
            }
        }
    }
    
    func removeTrainingHistory(for index: Int){
        let documentID = self.trainingHistory[index].documentID ?? ""
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        db.collection("users").document(Auth.auth().currentUser!.uid).collection("trainingStatistics").document(documentID).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
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
        
        for superset in routine.superset! {
            let sets:Int = superset.sets!
            let exercises:Int = superset.exercises!.count
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
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        
        //Update each exercise in Firebase
        for exercise in exerciseStatistics {
            let exerciseStats = db.collection("users").document(user).collection("exerciseStatistics").document()
            
            do {
                try exerciseStats.setData(from: exercise, merge: true)
            }
            catch {
                success = false
                return success
            }
        }
            
        //Update the training in Firebase
            
            let trainingStats = db.collection("users").document(user).collection("trainingStatistics").document()
            
            do {
                try trainingStats.setData(from: trainingStatisticsObject, merge: true)
            }
            catch {
                success = false
                return success
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
            self.exerciseStatistics = [ExerciseStatistics(id: UUID(), documentID: "", exerciseID: exercise.id, exerciseName: exercise.name, date: Date(), set: set, reps: reps, weight: 0)]
        } else {
            if let index = self.exerciseStatistics.firstIndex(where: { $0.exerciseID ==  exercise.id && $0.set == set}) {

                    let weight:Double = self.exerciseStatistics[index].weight ?? 0
                    self.exerciseStatistics[index] = ExerciseStatistics(id: UUID(), documentID: "", exerciseID: exercise.id, exerciseName: exercise.name, date: Date(), set: set, reps: reps, weight: weight)

            } else {
                //Initialize the stat
                self.exerciseStatistics.append(ExerciseStatistics(id: UUID(), documentID: "", exerciseID: exercise.id, exerciseName: exercise.name, date: Date(), set: set, reps: reps, weight: 0))
            }
        }
    }
    
    func createUpdateWeight(for exercise: Exercise, for set: Int, with weight: Double) {
        
        //check if self.exerciseStatistics is empty
        if self.exerciseStatistics.isEmpty {
            self.exerciseStatistics = [ExerciseStatistics(id: UUID(), documentID: "", exerciseID: exercise.id, exerciseName: exercise.name, date: Date(), set: set, reps: 0, weight: weight)]
        } else {
            if let index = self.exerciseStatistics.firstIndex(where: { $0.exerciseID ==  exercise.id && $0.set == set}) {
                
                    //Update the stat
                    let reps:Int = self.exerciseStatistics[index].reps ?? 0
                    self.exerciseStatistics[index] = ExerciseStatistics(id: UUID(), documentID: "", exerciseID: exercise.id, exerciseName: exercise.name, date: Date(), set: set, reps: reps, weight: weight)
            } else {
                //Initialize the stat
                self.exerciseStatistics.append(ExerciseStatistics(id: UUID(), documentID: "", exerciseID: exercise.id, exerciseName: exercise.name, date: Date(), set: set, reps: 0, weight: weight))
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
         documentID: String? = "",
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
    
    init(id: UUID = UUID(), documentID: String = "", exerciseID: UUID = UUID(), exerciseName:String = "", date:Date = DateHelper.from(year: 1970, month: 1, day: 1),set:Int = 0, reps:Int? = 0, weight:Double? = 0, estimatedOneRepMax:Double? = 0 ){
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
