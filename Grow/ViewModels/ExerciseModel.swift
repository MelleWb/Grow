//
//  ExerciseModel.swift
//  Grow
//
//  Created by Swen Rolink on 29/06/2021.
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

struct Exercise: Codable, Hashable, Identifiable {
    var id = UUID()
    @DocumentID var documentID: String?
    var userID: String?
    var name: String
    var reps: Int
    var durationMinutes: Int
    var distanceKilometers: Double
    var intervalCount: Int
    var workSeconds: Int
    var restSeconds: Int
    var category: String
    var imageURL: String?
    var description: String?
    var statistics: [ExerciseStatistics]?
    
    init(
        id: UUID = UUID(),
        documentID: String? = nil,
        userID: String? = nil,
        name: String? = nil,
        reps: Int = 0,
        durationMinutes: Int = 0,
        distanceKilometers: Double = 0,
        intervalCount: Int = 0,
        workSeconds: Int = 0,
        restSeconds: Int = 0,
        category: String? = nil,
        imageURL: String? = nil,
        description: String? = nil,
        statistics: [ExerciseStatistics]? = nil) {
        
        self.id = id
        self.documentID = documentID
        self.userID = userID
        self.name = name ?? "Naam"
        self.reps = reps
        self.durationMinutes = durationMinutes
        self.distanceKilometers = distanceKilometers
        self.intervalCount = intervalCount
        self.workSeconds = workSeconds
        self.restSeconds = restSeconds
        self.category = category ?? "Categorie"
        self.imageURL = imageURL ?? "Plaatje"
        self.description = description ?? "Omschrijving"
        self.statistics = statistics
    }

    enum CodingKeys: String, CodingKey {
        case id
        case documentID
        case userID
        case name
        case reps
        case durationMinutes
        case distanceKilometers
        case intervalCount
        case workSeconds
        case restSeconds
        case category
        case imageURL
        case description
        case statistics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = container.decodeUUIDIfPresent(forKey: .id) ?? UUID()
        self.documentID = nil
        self.userID = try container.decodeIfPresent(String.self, forKey: .userID)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Naam"
        self.reps = try container.decodeIfPresent(Int.self, forKey: .reps) ?? 0
        self.durationMinutes = try container.decodeIfPresent(Int.self, forKey: .durationMinutes) ?? 0
        self.distanceKilometers = try container.decodeIfPresent(Double.self, forKey: .distanceKilometers) ?? 0
        self.intervalCount = try container.decodeIfPresent(Int.self, forKey: .intervalCount) ?? 0
        self.workSeconds = try container.decodeIfPresent(Int.self, forKey: .workSeconds) ?? 0
        self.restSeconds = try container.decodeIfPresent(Int.self, forKey: .restSeconds) ?? 0
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
                    case .success(var exercise):
                        exercise.documentID = queryDocumentSnapshot.documentID
                        return exercise
                    case .failure:
                        print("error decoding exercise...")
                        return Exercise()
                    }
                }.filter { exercise in
                    guard let ownerUserID = exercise.userID, !ownerUserID.isEmpty else {
                        return true
                    }

                    return ownerUserID == Auth.auth().currentUser?.uid
                }
            }
        }
}
