//
//  TrainingModel.swift
//  Grow
//
//  Created by Swen Rolink on 05/07/2021.
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

class TrainingDataModel: ObservableObject{
    
    @Published var schema = Schema()
    @Published var fetchedSchemas = [Schema]()
    @Published var routine = Routine()
    var user = User()
    
    private var db = Firestore.firestore()
    
    init(){
        fetchData()
        initiateTrainingModel()
    }
    
    func initiateTrainingModel(){
        
        let db = Firestore.firestore()
        
        let docRef = db.collection("users").document(Auth.auth().currentUser!.uid)

        docRef.getDocument { (document, error) in
          if let document = document, document.exists {
            do{
                self.user = try document.data(as: User.self)
                self.loadRoutineFromSchema()
            }
            catch {
              print(error)
            }
          } else {
            print("User document does not exist")
          }
        }
    }
    
    func resetUser(user:  User){
        self.user = user
        self.loadRoutineFromSchema()
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
    
    
    func loadRoutineFromSchema(){
        guard
            let schemaID = self.user.schema,
            let todaysRoutine = self.user.workoutOfTheDay ?? self.getTodaysRoutine()
        else {
            self.routine = Routine()
            return
        }

        let db = Firestore.firestore()
        let docRef = db.collection("schemas").document(schemaID)

        docRef.getDocument { document, error in
            if (error as NSError?) != nil {
                print("Error getting document: \(error?.localizedDescription ?? "Unknown error")")
            } else if let document = document {
                do {
                    self.schema = try document.data(as: Schema.self)

                    if let index = self.schema.routines.firstIndex(where: { $0.id == todaysRoutine }) {
                        self.routine = self.schema.routines[index]
                    } else {
                        self.routine = Routine()
                    }
                }
                catch {
                    print(error)
                    self.routine = Routine()
                }
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
    
    func changeExcercise(toExercise: Exercise, forExercise: Exercise, superset: Superset){
        //To do
            if let supersetIndex = self.routine.superset.firstIndex(where: { $0.id == superset.id }) {
                if let exerciseIndex = self.routine.superset[supersetIndex].exercises.firstIndex(where: { $0.id == forExercise.id }) {
                    
                    self.routine.superset[supersetIndex].exercises[exerciseIndex].name = toExercise.name
                    
                    self.routine.superset[supersetIndex].exercises[exerciseIndex].description = toExercise.description
                    
                    self.routine.superset[supersetIndex].exercises[exerciseIndex].statistics = toExercise.statistics
                    
                    self.routine.superset[supersetIndex].exercises[exerciseIndex].documentID = toExercise.documentID
                    
                    self.routine.superset[supersetIndex].exercises[exerciseIndex].id = toExercise.id
            }
        }
        
    }
    
    func getAmountOfSets(for routine: Routine, for superset: Superset) -> Int{
        if let routineIndex = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if let supersetIndex = self.schema.routines[routineIndex].superset.firstIndex(where: { $0.id == superset.id }) {
                return self.schema.routines[routineIndex].superset[supersetIndex].sets
            }
            return 0
        }
        return 0
    }
    
    func getExercises(routine: Routine, for superset: Superset) -> [Exercise] {
        if let routineIndex = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if let supersetIndex = self.schema.routines[routineIndex].superset.firstIndex(where: { $0.id == superset.id }) {
                return self.schema.routines[routineIndex].superset[supersetIndex].exercises
            }
        }
        return [Exercise]()
    }
    
    func updateExercises(for routine: Routine, for superset: Superset, with exercises: [Exercise]) {
        if let routineIndex = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if let supersetIndex = self.schema.routines[routineIndex].superset.firstIndex(where: { $0.id == superset.id }) {
                // Just remove everything first
                self.schema.routines[routineIndex].superset[supersetIndex].exercises.removeAll()
                
                for exercise in exercises {
                    if self.schema.routines[routineIndex].superset[supersetIndex].exercises.isEmpty {
                        self.schema.routines[routineIndex].superset[supersetIndex].exercises.append(exercise)
                    } else {
                        self.schema.routines[routineIndex].superset[supersetIndex].exercises = [(exercise)]
                    }
                }
            }
        }
    }
    
    func updateExerciseReps(for routine: Routine, for superset: Superset, for exercise: Exercise, to reps: Int) {
        if let routineIndex = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if let supersetIndex = self.schema.routines[routineIndex].superset.firstIndex(where: { $0.id == superset.id }) {
                if let exerciseIndex = self.schema.routines[routineIndex].superset[supersetIndex].exercises.firstIndex(where: { $0.documentID == exercise.documentID }) {
                    self.schema.routines[routineIndex].superset[supersetIndex].exercises[exerciseIndex].reps = reps
                }
            }
        }
        
    }
    
    func removeExercise(for routine: Routine, for superset: Superset, for exerciseIndex: Int){
        if let routineIndex = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if let supersetIndex = self.schema.routines[routineIndex].superset.firstIndex(where: { $0.id == superset.id }) {
                
                self.schema.routines[routineIndex].superset[supersetIndex].exercises.remove(at: exerciseIndex)
            }
        }
    }
    
    func removeSuperset(for superset: Superset, for routine: Routine ){
        if let routineIndex = self.schema.routines.firstIndex(where: { $0.id == routine.id }) {
            if let supersetIndex = self.schema.routines[routineIndex].superset.firstIndex(where: { $0.id == superset.id }) {
                schema.routines[routineIndex].superset.remove(at: supersetIndex)
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
            return self.schema.routines[index].type
        }
        return ""
    }
        
    func fetchData() {
        
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
                        return Schema(id: schema.id, docID: schema.docID, type: schema.type, name: schema.name, routines: schema.routines)
                    case .failure(let error):
                        print("error decoding schema: \(error)")
                    }
                    
                    return Schema(type: "", name: "test")
                }
            }
        }
    
    func getTrainingSchema(for schemaDocID: String){
        
        let db = Firestore.firestore()
        
        let docRef = db.collection("schemas").document(schemaDocID)
          
        docRef.getDocument { document, error in
          if (error as NSError?) != nil {
              print("Error getting document: \(error?.localizedDescription ?? "Unknown error")")
          }
          else {
            if let document = document {
              do {
                self.schema = try document.data(as: Schema.self)
              }
              catch {
                print(error)
              }
            }
          }
        }
    }
    
    func createTraining(schema: Schema) -> Bool{
        // First create a proper schema name
        var schema: Schema = schema
        var schemaName: String = ""
        var volume: Double = 0.0
        let routineCount = schema.routines.count
        
        if schema.name == "" {
            schemaName += "\(routineCount)x-"
        
            for routines in self.schema.routines {
                let routineSubstring = routines.type.prefix(1)
                schemaName += routineSubstring
                
                for set in routines.superset{
                    let exerciseCount: Double = Double(set.exercises.count)
                    for exercise in set.exercises {
                        volume += (exerciseCount * Double(exercise.reps))
                    }
                }
            }
            
            schemaName += "-Volume:\(volume)"
            schema.name = schemaName
        }
        
        let db = Firestore.firestore()
        
        let newSchemaRef = db.collection("schemas").document()
        
        do {
            try newSchemaRef.setData(from: schema, merge: true)
        }
        catch let error {
            print(error)
            return false
        }
        return true
    }
    
    func updateTraining(schema: Schema){
        // First create a proper schema name
        var schema: Schema = schema
        var schemaName: String = ""
        var volume: Double = 0.0
        let routineCount = schema.routines.count
        
        if schema.name == "" {
            schemaName += "\(routineCount)x-"
        
            for routines in self.schema.routines {
                let routineSubstring = routines.type.prefix(1)
                schemaName += routineSubstring
                
                for set in routines.superset{
                    let exerciseCount: Double = Double(set.exercises.count)
                    for exercise in set.exercises {
                        volume += (exerciseCount * Double(exercise.reps))
                    }
                }
            }
            
            schemaName += "-Volume:\(volume)"
            schema.name = schemaName
        }
        
        let db = Firestore.firestore()
        
        let saveSchema: Schema = schema
        let newSchemaRef = db.collection("schemas").document(schema.docID!)
        
        do {
            try newSchemaRef.setData(from: saveSchema, merge: true)
        }
        catch let error {
            print(error)
        }
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

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case name
        case routines
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = container.decodeUUIDIfPresent(forKey: .id) ?? UUID()
        self.docID = nil
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.routines = try container.decodeIfPresent([Routine].self, forKey: .routines) ?? []
    }
}

struct Routine: Codable, Hashable, Identifiable {
    var id = UUID()
    var type: String
    var superset: [Superset]
    
    init(type: String = "Unknown",
         superset: [Superset] = [Superset]())
    {
        self.type = type
        self.superset = superset
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case superset
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = container.decodeUUIDIfPresent(forKey: .id) ?? UUID()
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? "Unknown"
        self.superset = try container.decodeIfPresent([Superset].self, forKey: .superset) ?? []
    }
}

struct Superset: Codable, Hashable, Identifiable {
    var id = UUID()
    var sets: Int
    var exercises: [Exercise]
    
    init(sets: Int = 0,exercises: [Exercise] = [Exercise]()){
        self.sets = sets
        self.exercises = exercises
    }

    enum CodingKeys: String, CodingKey {
        case id
        case sets
        case exercises
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = container.decodeUUIDIfPresent(forKey: .id) ?? UUID()
        self.sets = try container.decodeIfPresent(Int.self, forKey: .sets) ?? 0
        self.exercises = try container.decodeIfPresent([Exercise].self, forKey: .exercises) ?? []
    }
}
