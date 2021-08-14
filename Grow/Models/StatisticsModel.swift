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
    @Published var thisWeeksStats = TrainingStatistics()
    var trainingStatistics = TrainingStatistics()
    
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
    
    func getWeightForSet(for exercise: Exercise, for set: Int) -> Int {
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

                    let weight:Int = self.exerciseStatistics[index].weight ?? 0
                    self.exerciseStatistics[index] = ExerciseStatistics(id: UUID(), documentID: "", exerciseID: exercise.id, exerciseName: exercise.name, set: set, reps: reps, weight: weight)

            } else {
                //Initialize the stat
                self.exerciseStatistics.append(ExerciseStatistics(id: UUID(), documentID: "", exerciseID: exercise.id, exerciseName: exercise.name, set: set, reps: reps, weight: 0))
            }
        }
    }
    
    func createUpdateWeight(for exercise: Exercise, for set: Int, with weight: Int) {
        
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
    var id = UUID()
    @DocumentID var documentID: String?
    var exerciseID: UUID
    var exerciseName: String
    var date: Date
    var set: Int
    var reps: Int?
    var weight: Int?
    
    init(id: UUID, documentID: String, exerciseID: UUID, exerciseName:String = "", date:Date = Date(),set:Int = 0, reps:Int? = 0, weight:Int? = 0 ){
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
