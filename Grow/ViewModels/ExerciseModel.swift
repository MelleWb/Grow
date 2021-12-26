//
//  ExerciseModel.swift
//  Grow
//
//  Created by Swen Rolink on 29/06/2021.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct Exercise: Codable, Hashable, Identifiable {
    var id = UUID()
    @DocumentID var documentID: String?
    var name: String
    var reps: Int?
    var category: String
    var imageURL: String?
    var description: String?
    var statistics: [ExerciseStatistics]?
    
    init(
        id: UUID = UUID(),
        documentID: String,
        name: String? = nil,
        reps: Int? = 0,
        category: String? = nil,
        imageURL: String? = nil,
        description: String? = nil,
        statistics: [ExerciseStatistics]? = nil) {
        
        self.id = id
        self.documentID = documentID
        self.name = name ?? ""
        self.reps = reps
        self.category = category ?? ""
        self.imageURL = imageURL ?? ""
        self.description = description ?? ""
        self.statistics = statistics
    }
}

class ExerciseDataModel: ObservableObject{
    
    @Published var exercises = [Exercise]()
    
    private var db = Firestore.firestore()
    
    init(){
        fetchData()
    }
    
    func fetchData() {
        db.collection("exercises").order(by: "name").addSnapshotListener { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("No documents")
                    return
                }
                
                self.exercises = documents.map { (queryDocumentSnapshot) -> Exercise in
                    let data = queryDocumentSnapshot.data()
                    
                    let name = data["name"] as? String ?? ""
                    let category = data["category"] as? String ?? ""
                    let imageURL = data["category"] as? String ?? ""
                    let description = data["description"] as? String ?? ""
                    let documentID = queryDocumentSnapshot.documentID
                    
                    return Exercise(documentID: documentID, name: name, category: category, imageURL: imageURL, description: description)
                }
            }
        }
}
