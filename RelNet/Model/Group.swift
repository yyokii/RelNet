//
//  Group.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/29.
//

import Foundation

import FirebaseFirestore
import FirebaseFirestoreSwift

struct Group: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var name: String = ""
    var description: String?

    @ServerTimestamp var createdAt: Timestamp?
    var updatedAt: Timestamp?
}

extension Group {
    static let mock = Self (
        id: UUID().uuidString,
        name: "😄demo name",
        description: "this is description."
    )
}

