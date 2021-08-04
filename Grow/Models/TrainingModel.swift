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
    @Published var routine = Routine()
    
    private var db = Firestore.firestore()
    
    func loadRoutineFromSchema(for schema: String, for routine: UUID){
        if self.schema.name.isEmpty{
            
            let settings = FirestoreSettings()
            settings.isPersistenceEnabled = true
            let db = Firestore.firestore()
            
            let docRef = db.collection("schemas").document(schema)
              
            docRef.getDocument { document, error in
              if (error as NSError?) != nil {
                  print("Error getting document: \(error?.localizedDescription ?? "Unknown error")")
              }
              else {
                if let document = document {
                  do {
                    self.schema = try document.data(as: Schema.self)!
                    
                    if let index = self.schema.routines.firstIndex(where: { $0.id == routine }) {
                            self.routine = self.schema.routines[index]
                        }
                  }
                  catch {
                    print(error)
                  }
                }
              }
            }
            
        }
        else {
            if let index = self.schema.routines.firstIndex(where: { $0.id == routine }) {
                    self.routine = self.schema.routines[index]
                }
        }
    }
    
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
            if self.schema.routines[index].superset != nil {
                self.schema.routines[index].superset?.append(superset)
            } else {
                self.schema.routines[index].superset? = [superset]
            }
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
    
    func updateSets(for routine: Routine, for superset: Superset, to amountOfSets: Int){
        if let routineIndex = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if let supersetIndex = self.schema.routines[routineIndex].superset?.firstIndex(where: { $0.id == superset.id }) {
                    self.schema.routines[routineIndex].superset?[supersetIndex].sets = amountOfSets

            }
        }
    }
    
    func getAmountOfSets(for routine: Routine, for superset: Superset) -> Int{
        if let routineIndex = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if let supersetIndex = self.schema.routines[routineIndex].superset?.firstIndex(where: { $0.id == superset.id }) {
                return self.schema.routines[routineIndex].superset?[supersetIndex].sets ?? 0
            }
            return 0
        }
        return 0
    }
    
    func getExercises(routine: Routine, for superset: Superset) -> [Exercise] {
        if let routineIndex = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if let supersetIndex = self.schema.routines[routineIndex].superset?.firstIndex(where: { $0.id == superset.id }) {
                if self.schema.routines[routineIndex].superset![supersetIndex].exercises != nil {
                    return self.schema.routines[routineIndex].superset![supersetIndex].exercises!
                }
            }
        }
        return [Exercise]()
    }
    
    func updateExercises(for routine: Routine, for superset: Superset, with exercises: [Exercise]) {
        if let routineIndex = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if let supersetIndex = self.schema.routines[routineIndex].superset?.firstIndex(where: { $0.id == superset.id }) {
                // Just remove everything first
                self.schema.routines[routineIndex].superset![supersetIndex].exercises?.removeAll()
                
                for exercise in exercises {
                    if self.schema.routines[routineIndex].superset![supersetIndex].exercises != nil {
                    self.schema.routines[routineIndex].superset![supersetIndex].exercises?.append(exercise)
                    } else {
                        self.schema.routines[routineIndex].superset![supersetIndex].exercises? = [(exercise)]
                    }
                }
            }
        }
    }
    
    func updateExerciseReps(for routine: Routine, for superset: Superset, for exercise: Exercise, to reps: Int) {
        if let routineIndex = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if let supersetIndex = self.schema.routines[routineIndex].superset?.firstIndex(where: { $0.id == superset.id }) {
                if let exerciseIndex = self.schema.routines[routineIndex].superset![supersetIndex].exercises!.firstIndex(where: { $0.documentID == exercise.documentID }) {
                    self.schema.routines[routineIndex].superset![supersetIndex].exercises![exerciseIndex].reps = reps
                }
            }
        }
        
    }
    
    func removeExercise(for routine: Routine, for superset: Superset, for exerciseIndex: Int){
        if let routineIndex = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if let supersetIndex = self.schema.routines[routineIndex].superset?.firstIndex(where: { $0.id == superset.id }) {
                
                self.schema.routines[routineIndex].superset?[supersetIndex].exercises?.remove(at: exerciseIndex)
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
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
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
                            return Schema(id: schema.id, docID: schema.docID, type: schema.type, name: schema.name, routines: schema.routines)
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
    
    func getTrainingSchema(for schemaDocID: String){
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        let docRef = db.collection("schemas").document(schemaDocID)
          
        docRef.getDocument { document, error in
          if (error as NSError?) != nil {
              print("Error getting document: \(error?.localizedDescription ?? "Unknown error")")
          }
          else {
            if let document = document {
              do {
                self.schema = try document.data(as: Schema.self)!
              }
              catch {
                print(error)
              }
            }
          }
        }
    }
    
    func createTraining() -> Bool{
        
        // First create a proper schema name
        var schemaName: String = ""
        var volume: Double = 0.0
        let routineCount = self.schema.routines.count
        
        schemaName += "\(routineCount)x-"
        
        for routines in self.schema.routines {
            let routineSubstring = routines.type?.prefix(1) ?? "?"
            schemaName += routineSubstring
            
            for set in routines.superset ?? []{
                let exerciseCount: Double = Double(set.exercises?.count ?? 0)
                for exercise in set.exercises ?? [] {
                    volume += exerciseCount * Double(exercise.reps ?? 0)
                }
            }
        }
        
        schemaName += "-Volume:\(volume)"
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
    @DocumentID var docID: String?
    var id: UUID
    var type: String
    var name: String
    var routines: [Routine]
    
    init(id:UUID = UUID(),
         docID: String? = nil,
         documentID: String? = nil,
         type: String = "",
         name: String = "",
         routines: [Routine] = [Routine]()
    )
    {
        self.id = id
        self.docID = docID
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
         superset: [Superset] = [Superset]())
    {
        self.type = type
        self.superset = superset
    }
}

struct Superset: Codable, Hashable, Identifiable {
    var id = UUID()
    var sets: Int?
    var exercises: [Exercise]?
    
    init(sets: Int = 0,exercises: [Exercise] = [Exercise]()){
        self.sets = sets
        self.exercises = exercises
    }
}

struct Set: Codable, Hashable {
    var reps: Int
    var weight: Int
}
