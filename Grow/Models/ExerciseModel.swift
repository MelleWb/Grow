//
//  ExerciseModel.swift
//  Grow
//
//  Created by Swen Rolink on 29/06/2021.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct Exercise: Codable, Hashable {
    @DocumentID var documentID: String?
    var name: String
    var category: String
    var imageURL: String?
    var description: String?
    
    init(
        documentID: String?,
        name: String? = nil,
        category: String? = nil,
        imageURL: String? = nil,
        description: String? = nil) {
        
        self.documentID = documentID
        self.name = name ?? ""
        self.category = category ?? ""
        self.imageURL = imageURL ?? ""
        self.description = description ?? ""
    }
}

class ExerciseDataModel: ObservableObject{
    
    @Published var exercises = [Exercise]()
    
    private var db = Firestore.firestore()
    
    func fetchData() {
            db.collection("exercises").addSnapshotListener { (querySnapshot, error) in
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
