//
//  Group.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/29.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct Group: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    var name: String = ""
    var description: String = ""

    @ServerTimestamp var createdAt: Timestamp?
    var updatedAt: Timestamp?
}

extension Group {
    static func mock(
        id: String = UUID().uuidString,
        name: String = "🦄 demo",
        description: String = "this is description"
    ) -> Self {
        .init(
            id: id,
            name: name,
            description: description
        )
    }

    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [
            "name": name,
            "description": description,
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
