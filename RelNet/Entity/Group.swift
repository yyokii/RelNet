//
//  Group.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/29.
//

import Foundation

import FirebaseFirestore
import FirebaseFirestoreSwift

struct Group: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    var name: String = ""
    var description: String = ""

    @ServerTimestamp var createdAt: Timestamp?
    var updatedAt: Timestamp?
}

extension Group {
    static let mock = Self (
        id: "id-1",
        name: "😄demo name",
        description: "this is description."
    )

    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [
            "name": name,
            "description": description
        ]

        if let createdAt {
            dictionary["createdAt"] = createdAt
        }

        if let updatedAt {
            dictionary["updatedAt"] = updatedAt
        }

        return dictionary
    }
}

