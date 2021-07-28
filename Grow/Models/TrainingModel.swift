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
    
    private var db = Firestore.firestore()
    
    func setSingleSchemaFromFetchedSchemas(for schema:Schema) {
        if let index = self.fetchedSchemas.firstIndex(where: { $0.id == schema.id }) {
            self.schema = self.fetchedSchemas[index]
        }
    }
    
    func addRoutine(for routine: Routine) {
        if let index = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if index == -1 {
                self.schema.routines.append(routine)
            } else {
                self.schema.routines.remove(at: index)
                self.schema.routines.append(routine)
            }
        }
        else{
            schema.routines.append(routine)
        }
    }
    
    func addSuperset(for routine: Routine){
        if let index = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            let superset: Superset = Superset()
            self.schema.routines[index].superset?.append(superset)
        }
    }
    
    func getSupersetIndex(for routine: Routine, for superset: Superset) -> Int{
        if let routineIndex = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if let supersetIndex = self.schema.routines[routineIndex].superset?.firstIndex(where: { $0.id == superset.id }) {
                return supersetIndex
            }
            return 0
        }
        return 0
    }
    
    func updateSets(for routine: Routine, for superset: Superset, to sets: Int){
        if let routineIndex = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if let supersetIndex = self.schema.routines[routineIndex].superset?.firstIndex(where: { $0.id == superset.id }) {
                self.schema.routines[routineIndex].superset?[supersetIndex].sets = sets
            }
        }
    }
        
    func updateReps(for routine: Routine, for superset: Superset, to reps: Int){
        if let routineIndex = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if let supersetIndex = self.schema.routines[routineIndex].superset?.firstIndex(where: { $0.id == superset.id }) {
                self.schema.routines[routineIndex].superset?[supersetIndex].reprange = reps
            }
        }
    }
    
    func getExerciseIndex(for routine: Routine, for superset: Superset, for exercise: ExerciseInfo) -> Int{
        if let routineIndex = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if let supersetIndex = self.schema.routines[routineIndex].superset?.firstIndex(where: { $0.id == superset.id }) {
                if let exerciseIndex = self.schema.routines[routineIndex].superset?[supersetIndex].exercise?.firstIndex(where: { $0.id == exercise.id }) {
                    return exerciseIndex
                }
                return 0
            }
            return 0
        }
        return 0
    }
    
    func addExerciseToSuperset(for routine: Routine, for superset: Superset) {
        if let routineIndex = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if let supersetIndex = self.schema.routines[routineIndex].superset?.firstIndex(where: { $0.id == superset.id }) {
                let exercise: ExerciseInfo = ExerciseInfo()
                self.schema.routines[routineIndex].superset?[supersetIndex].exercise?.append(exercise)
            }
        }
    }
    
    func updateExercise(for routine: Routine, for superset: Superset, for exercise: ExerciseInfo, to exerciseName: String) {
        if let routineIndex = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if let supersetIndex = self.schema.routines[routineIndex].superset?.firstIndex(where: { $0.id == superset.id }) {
                if let exerciseIndex = self.schema.routines[routineIndex].superset?[supersetIndex].exercise?.firstIndex(where: { $0.id == exercise.id }) {
                    
                    self.schema.routines[routineIndex].superset?[supersetIndex].exercise?[exerciseIndex].name = exerciseName
                }
            }
        }
    }
    
    func removeExercise(for routine: Routine, for superset: Superset, for exerciseIndex: Int){
        if let routineIndex = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if let supersetIndex = self.schema.routines[routineIndex].superset?.firstIndex(where: { $0.id == superset.id }) {
                
                self.schema.routines[routineIndex].superset?[supersetIndex].exercise?.remove(at: exerciseIndex)
            }
        }
    }
    
    func removeSuperset(for superset: Superset, for routine: Routine ){
        if let routineIndex = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if let supersetIndex = self.schema.routines[routineIndex].superset?.firstIndex(where: { $0.id == superset.id }) {
                schema.routines[routineIndex].superset?.remove(at: supersetIndex)
                }
        }
    }
    
    func getRoutineIndex(for routine: Routine) -> Int{
        if let index = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            return index
        } else {
            return 0
        }
    }
    
    func updateRoutineType(for routine: Routine, to type: String) {
        
        if let index = self.schema.routines.firstIndex(where: { $0.id == routine.id}) {
            self.schema.routines[index].type = type
        }
    }
    
    func getRoutineType(for routine: Routine) -> String {
        
        if let index = self.schema.routines.firstIndex(where: { $0.id == routine.id}) {
            return self.schema.routines[index].type ?? ""
        }
        return ""
    }
        
    func fetchData() {
        
        db.collection("schemas").addSnapshotListener { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("No documents")
                    return
                }
                
                self.fetchedSchemas = documents.map { (queryDocumentSnapshot) -> Schema in
                    
                    let result = Result {
                        try queryDocumentSnapshot.data(as: Schema.self)
                    }
                    switch result {
                    case .success(let schema):
                        if let schema = schema {
                            return Schema(id: schema.id, type: schema.type, name: schema.name, routines: schema.routines)
                        }
                        else {
                            print ("Document does not exists")
                        }
                    case .failure(let error):
                        print("error decoding schema: \(error)")
                    }
                    
                    return Schema(type: "", name: "test")
                }
            }
        }
    
    func createTraining() -> Bool{
        
        // First create a proper schema name
        var schemaName: String = ""
        var load: Double = 0.0
        let routineCount = self.schema.routines.count
        
        schemaName += "\(routineCount)x-"
        
        for routines in self.schema.routines {
            let routineSubstring = routines.type?.prefix(1) ?? "?"
            schemaName += routineSubstring
            
            for set in routines.superset ?? []{
                load += Double((set.reprange * set.sets))
            }
        }
        
        schemaName += "-Load:\(load)"
        self.schema.name = schemaName
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        let saveSchema: Schema = self.schema
        let newSchemaRef = db.collection("schemas").document()
        
        do {
            try newSchemaRef.setData(from: saveSchema, merge: true)
        }
        catch let error {
            print(error)
            return false
        }
        return true
    }
    
    func updateTraining(){
        //Do Something
    }
}


struct Schema: Codable, Hashable, Identifiable  {
    var id: UUID
    var type: String
    var name: String
    var routines: [Routine]
    
    init(id:UUID = UUID(),
         documentID: String? = nil,
         type: String = "",
         name: String = "",
         routines: [Routine] = [Routine]()
    )
    {
        self.id = id
        //self.documentID = documentID
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
    var exercise: [ExerciseInfo]?
    
    init(sets: Int = 0, reprange: Int = 0,exercise: [ExerciseInfo] = [ExerciseInfo()]){
        self.sets = sets
        self.reprange = reprange
        self.exercise = exercise
    }
}

struct ExerciseInfo: Codable, Hashable, Identifiable {
    var id = UUID()
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
