//
//  Person.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/24.
//

import Foundation

import FirebaseFirestore
import FirebaseFirestoreSwift

struct Person: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var firstName: String = "" // 姓
    var firstNameFurigana: String?
    var lastName: String = "" // 名
    var lastNameFurigana: String?
    var nickname: String = ""
    var birthdate: Date?
    var notes: String = ""
    var address: String?
    var lastContacted: Date?
    private(set) var groupIDs: [String] = []

    @ServerTimestamp var createdAt: Timestamp?
    var updatedAt: Timestamp?

    var name: String {
        if !nickname.isEmpty {
            return nickname
        } else if
            !firstName.isEmpty,
            !lastName.isEmpty {
            return firstName + " " + lastName
        } else {
            return firstName.isEmpty ? lastName : firstName
        }
    }
}

extension Person {
    static let mock = Self (
        id: UUID().uuidString,
        firstName: "DemoFirst",
        lastName: "DemoLast",
        nickname: "Nick",
        birthdate: Date(),
        notes: "this is note.",
        address: "Japan",
        lastContacted: Date(),
        groupIDs: ["id-1"]
    )

    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "nickname": nickname,
            "groupIDs": groupIDs,
            "notes": notes
        ]

        if let firstNameFurigana {
            dictionary["firstNameFurigana"] = firstNameFurigana
        }

        if let lastNameFurigana {
            dictionary["lastNameFurigana"] = lastNameFurigana
        }

        if let birthdate {
            dictionary["birthdate"] = birthdate
        }

        if let address {
            dictionary["address"] = address
        }

        if let lastContacted {
            dictionary["lastContacted"] = lastContacted
        }

        if let createdAt {
            dictionary["createdAt"] = createdAt
        }

        if let updatedAt {
            dictionary["updatedAt"] = updatedAt
        }

        return dictionary
    }

    mutating func updateGroupID(_ id: String) {
        if !groupIDs.contains(id) {
            groupIDs.append(id)
        } else {
            groupIDs.removeAll { $0 == id }
        }
    }
}
