//
//  User.swift
//  Grow
//
//  Created by Swen Rolink on 30/11/2021.
//

import Foundation
import UIKit
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

struct User: Codable {
    @DocumentID var id: String?
    var role: UserRole?
    var firstName: String?
    var lastName: String?
    var dateOfBirth: Date?
    var gender: Int?
    var coach: String?
    var coachPictureURL: String?
    var userImageURL: String?
    var height: Int?
    var weight: Int?
    var plan: Int?
    var kcal: Int?
    var proteinRatio: Double?
    var fatRatio: Double?
    var nmbrOfTrainings: Int?
    var pal: Int?
    var fcmToken: String?
    var schema: String?
    var weekPlan: [DayPlan]?
    var workoutOfTheDay: UUID?
    var restCalories: Macros?
    var sportCalories: Macros?
    var extraCaloriePercentage: Int?
    var membership: MemberShip?
}

extension User {
    var isAdmin: Bool {
        role == .admin
    }

    var hasRequiredProfileData: Bool {
        let hasFirstName = firstName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let hasLastName = lastName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let hasWeight = weight != nil
        let hasHeight = height != nil
        let hasPlan = plan != nil
        let hasPal = pal != nil
        let hasSchema = schema?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false

        return hasFirstName && hasLastName && hasWeight && hasHeight && hasPlan && hasPal && hasSchema
    }
}

enum UserRole: String, Codable {
    case admin
    case member

    var displayName: String {
        switch self {
        case .admin:
            return "Admin"
        case .member:
            return "Member"
        }
    }
}

enum FamilyInviteStatus: String, Codable {
    case pending

    var displayName: String {
        switch self {
        case .pending:
            return "Uitgenodigd"
        }
    }
}

enum FamilyLinkStatus: String, Codable {
    case active

    var displayName: String {
        switch self {
        case .active:
            return "Actief"
        }
    }
}

struct FamilyInvite: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var fromUserID: String = ""
    var fromEmail: String?
    var fromDisplayName: String?
    var toUserID: String = ""
    var toEmail: String?
    var toDisplayName: String?
    var status: FamilyInviteStatus = .pending
    var createdAt: Date?
    var updatedAt: Date?

    var displayName: String {
        if let toDisplayName, toDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return toDisplayName
        }
        if let fromDisplayName, fromDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return fromDisplayName
        }
        return toEmail ?? fromEmail ?? "Onbekend"
    }

    var stableIdentifier: String {
        id ?? "\(fromUserID)_\(toUserID)"
    }
}

struct FamilyMember: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var userID: String = ""
    var email: String?
    var displayName: String?
    var status: FamilyLinkStatus = .active
    var linkedAt: Date?
    var createdBy: String?

    var resolvedDisplayName: String {
        if let displayName, displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return displayName
        }
        return email ?? "Onbekend"
    }

    var stableIdentifier: String {
        userID
    }
}

struct MemberShip: Codable, Identifiable, Hashable {
    var id = UUID()
    var product: String?
    var isPremiumMember: Bool?
    var isRenewable: Bool?
    var startDate: Date?
    var endDate: Date?
}


struct UserImages {
    var userImage: UIImage?
    var coachImage: UIImage?
}

struct DayPlan: Codable, Identifiable, Hashable {
    var id = UUID()
    var trainingType: String?
    var routine: UUID?
    var isTrainingDay: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case trainingType
        case routine
        case isTrainingDay
    }

    init(
        id: UUID = UUID(),
        trainingType: String? = nil,
        routine: UUID? = nil,
        isTrainingDay: Bool? = nil
    ) {
        self.id = id
        self.trainingType = trainingType
        self.routine = routine
        self.isTrainingDay = isTrainingDay
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = container.decodeUUIDIfPresent(forKey: .id) ?? UUID()
        self.trainingType = try container.decodeIfPresent(String.self, forKey: .trainingType)
        self.routine = container.decodeUUIDIfPresent(forKey: .routine)
        self.isTrainingDay = try container.decodeIfPresent(Bool.self, forKey: .isTrainingDay)
    }
}

struct BodyMeasurement: Codable, Identifiable, Hashable {
    
    var id = UUID()
    var date: Date
    @DocumentID var documentID: String?
    
    var smallFrontImageUrl: String
    var smallSideImageUrl: String
    var smallBackImageUrl: String
    
    var largeFrontImageUrl: String
    var largeSideImageUrl: String
    var largeBackImageUrl: String
    
    var weight: Double? = 0
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        documentID:String? = nil,
        smallFrontImageUrl: String = "",
        smallSideImageUrl: String = "",
        smallBackImageUrl: String = "",
        largeFrontImageUrl: String = "",
        largeSideImageUrl: String = "",
        largeBackImageUrl: String = "",
        weight: Double? = 0
    ){
        self.id = id
        self.date = date
        self.documentID = documentID
        self.smallFrontImageUrl = smallFrontImageUrl
        self.smallSideImageUrl = smallSideImageUrl
        self.smallBackImageUrl = smallBackImageUrl
        self.largeFrontImageUrl = largeFrontImageUrl
        self.largeSideImageUrl = largeSideImageUrl
        self.largeBackImageUrl = largeBackImageUrl
        self.weight = weight
    }
}
