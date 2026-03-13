//
//  ExerciseModel.swift
//  Grow
//
//  Created by Swen Rolink on 29/06/2021.
//

import Foundation
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

struct Exercise: Codable, Hashable, Identifiable {
    var id = UUID()
    @DocumentID var documentID: String?
    var name: String
    var reps: Int
    var category: String
    var imageURL: String?
    var description: String?
    var statistics: [ExerciseStatistics]?
    
    init(
        id: UUID = UUID(),
        documentID: String? = nil,
        name: String? = nil,
        reps: Int = 0,
        category: String? = nil,
        imageURL: String? = nil,
        description: String? = nil,
        statistics: [ExerciseStatistics]? = nil) {
        
        self.id = id
        self.documentID = documentID
        self.name = name ?? "Naam"
        self.reps = reps
        self.category = category ?? "Categorie"
        self.imageURL = imageURL ?? "Plaatje"
        self.description = description ?? "Omschrijving"
        self.statistics = statistics
    }

    enum CodingKeys: String, CodingKey {
        case id
        case documentID
        case name
        case reps
        case category
        case imageURL
        case description
        case statistics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = container.decodeUUIDIfPresent(forKey: .id) ?? UUID()
        self.documentID = nil
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Naam"
        self.reps = try container.decodeIfPresent(Int.self, forKey: .reps) ?? 0
        self.category = try container.decodeIfPresent(String.self, forKey: .category) ?? "Categorie"
        self.imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.statistics = try container.decodeIfPresent([ExerciseStatistics].self, forKey: .statistics)
    }
}

class ExerciseDataModel: ObservableObject{
    
    @Published var exercises = [Exercise]()
    
    private var db = Firestore.firestore()
    
    init(){
        //fetchData()
    }
    
    func fetchData() {
        db.collection("exercises").order(by: "name").addSnapshotListener { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("No documents")
                    return
                }
                
                self.exercises = documents.map { (queryDocumentSnapshot) -> Exercise in
                    let result = Result {
                        try queryDocumentSnapshot.data(as: Exercise.self)
                    }

                    switch result {
                    case .success(let exercise):
                        return exercise
                    case .failure:
                        print("error decoding exercise...")
                        return Exercise()
                    }
                }
            }
        }
}
