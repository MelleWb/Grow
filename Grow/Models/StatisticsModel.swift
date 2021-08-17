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
    var trainingStatistics = TrainingStatistics()
    
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
            print(self.maxWeight)
            
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
        .whereField("exerciseName", isEqualTo: exerciseName).order(by: "weight", descending: true).limit(to: 50).addSnapshotListener { (querySnapshot, error) in

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
                            return ExerciseStatistics(id: stats.id, documentID: stats.documentID ?? "", exerciseID: stats.exerciseID, exerciseName: stats.exerciseName, date: stats.date, set: stats.set, reps: stats.reps, weight: stats.weight)
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
        
    func getStatisticsForCurrentSchema(for user: String, for schemaString: String){
        
        var schema:Schema = Schema()
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        let docRef = db.collection("schemas").document(schemaString)
        
        docRef.getDocument { document, error in
          if (error as NSError?) != nil {
              print("Error getting document: \(error?.localizedDescription ?? "Unknown error")")
          }
          else {
            if let document = document {
              do {
                schema = try document.data(as: Schema.self)!
              }
              catch {
                print(error)
              }
            }
          }
        }
        
        //Get routines for current schema
        for routine in schema.routines {
            
            var routineStats: RoutineStatistics = RoutineStatistics(type: routine.type ?? "")
            
            let routineString:String = routine.id.uuidString
            
            db.collection("users").document(user).collection("trainingStatistics")
                .whereField("routine", isEqualTo: routineString).addSnapshotListener { (querySnapshot, error) in
                    
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
                                return TrainingStatistics(id: stats.id, routineID: stats.routineID, documentID: stats.documentID, trainingDate: stats.trainingDate, trainingVolume: stats.trainingVolume)
                            }
                            else {
                                print ("Document does not exists")
                            }
                        case .failure(let error):
                            print("error decoding schema: \(error)")
                        }
                        return TrainingStatistics(routineID: UUID(), trainingDate: DateHelper.from(year: 1970, month: 1, day: 1), trainingVolume: 0)
                    }
                }
            if self.schemaStatistics.routineStats != nil {
                self.schemaStatistics.routineStats?.append(routineStats)
                } else {
                    self.schemaStatistics.routineStats = [routineStats]
                }
            }
        }
    
    func saveTraining(for user: String, for routineID: UUID) -> Bool{

        var volume:Double = 0
        let date = Date()
        var success: Bool = true
        
        //Calculate volume
        for stats in exerciseStatistics{
            volume += (Double(stats.reps ?? 0) * Double(stats.weight ?? 0))
            }
        
        self.trainingStatistics = TrainingStatistics(routineID: routineID, trainingDate: date, trainingVolume: volume)
        
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
                try trainingStats.setData(from: trainingStatistics, merge: true)
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
        print(exercise)
        //check if self.exerciseStatistics is empty
        if self.exerciseStatistics.isEmpty {
            self.exerciseStatistics = [ExerciseStatistics(id: UUID(), documentID: "", exerciseID: exercise.id, exerciseName: exercise.name, set: set, reps: reps, weight: 0)]
        } else {
            if let index = self.exerciseStatistics.firstIndex(where: { $0.exerciseID ==  exercise.id && $0.set == set}) {

                    let weight:Double = self.exerciseStatistics[index].weight ?? 0
                    self.exerciseStatistics[index] = ExerciseStatistics(id: UUID(), documentID: "", exerciseID: exercise.id, exerciseName: exercise.name, set: set, reps: reps, weight: weight)

            } else {
                //Initialize the stat
                self.exerciseStatistics.append(ExerciseStatistics(id: UUID(), documentID: "", exerciseID: exercise.id, exerciseName: exercise.name, set: set, reps: reps, weight: 0))
            }
        }
    }
    
    func createUpdateWeight(for exercise: Exercise, for set: Int, with weight: Double) {
        
        //check if self.exerciseStatistics is empty
        if self.exerciseStatistics.isEmpty {
            self.exerciseStatistics = [ExerciseStatistics(id: UUID(), documentID: "", exerciseID: exercise.id, exerciseName: exercise.name, set: set, reps: 0, weight: weight)]
        } else {
            if let index = self.exerciseStatistics.firstIndex(where: { $0.exerciseID ==  exercise.id && $0.set == set}) {
                
                    //Update the stat
                    let reps:Int = self.exerciseStatistics[index].reps ?? 0
                    self.exerciseStatistics[index] = ExerciseStatistics(id: UUID(), documentID: "", exerciseID: exercise.id, exerciseName: exercise.name, set: set, reps: reps, weight: weight)
            } else {
                //Initialize the stat
                self.exerciseStatistics.append(ExerciseStatistics(id: UUID(), documentID: "", exerciseID: exercise.id, exerciseName: exercise.name, set: set, reps: 0, weight: weight))
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
    
    init(id: UUID = UUID(),
         routineID: UUID = UUID(),
         documentID: String? = "",
         trainingDate: Date = DateHelper.from(year: 1, month: 1, day: 1970),
         trainingVolume: Double = 0)
        {
        self.id = id
        self.routineID = routineID
        self.documentID = documentID
        self.trainingDate = trainingDate
        self.trainingVolume = trainingVolume
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
    
    init(id: UUID = UUID(), documentID: String = "", exerciseID: UUID = UUID(), exerciseName:String = "", date:Date = DateHelper.from(year: 1970, month: 1, day: 1),set:Int = 0, reps:Int? = 0, weight:Double? = 0 ){
        self.id = id
        self.documentID = documentID
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.date = date
        self.set = set
        self.reps = reps
        self.weight = weight
    }
}

struct SchemaStatistics: Codable, Identifiable, Hashable {
    var id = UUID()
    var routineStats: [RoutineStatistics]?
    
    init(id:UUID = UUID(), routineStats: [RoutineStatistics] = [RoutineStatistics()]){
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
