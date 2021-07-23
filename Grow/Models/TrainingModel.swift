//
//  TrainingModel.swift
//  Grow
//
//  Created by Swen Rolink on 05/07/2021.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

class TrainingDataModel: ObservableObject{
    @Published var schema = Schema()
    
    @Published var fetchedSchemas = [Schema]()
    
    func fetchTraining(){
        //Do Something
    }
    
    func saveTraining(){
        //Do Something
    }
    
    func updateTraining(){
        //Do Something
    }
}


struct Schema: Codable, Hashable, Identifiable  {
    @DocumentID var documentID: String?
    var id: UUID
    var type: String
    var name: String
    var routines: [Routine]?
    
    init(id:UUID = UUID(),
         documentID: String? = nil,
         type: String = "",
         name: String = "",
         routines: [Routine]? = nil
    )
    {
        self.id = id
        self.documentID = documentID
        self.type = type
        self.name = name
        self.routines = routines
    }
}

struct Routine: Codable, Hashable, Identifiable {
    var id = UUID()
    var type: String?
    var superset: [Superset]?
    
    init(type: String = "Unknown",
         superset: [Superset] = [Superset()])
    {
        self.type = type
        self.superset = superset
    }
}

struct Superset: Codable, Hashable, Identifiable {
    var id = UUID()
    var sets: Int
    var reprange: Int
    var exercise: [ExerciseInfo]
    
    init(sets: Int = 0, reprange: Int = 0,exercise: [ExerciseInfo] = [ExerciseInfo()]){
        self.sets = sets
        self.reprange = reprange
        self.exercise = exercise
        
        
    }
}

struct ExerciseInfo: Codable, Hashable {
    var name: String

    init(name: String = "",
         sets: Int = 0,
         reprange: Int = 0){
        self.name = name
    }
}

struct Set: Codable, Hashable {
    var reps: Int
    var weight: Int
    
    static func ==(lhs: Set, rhs: Set) -> Bool {
        return lhs.reps == rhs.reps
        }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(reps)
    }
}
