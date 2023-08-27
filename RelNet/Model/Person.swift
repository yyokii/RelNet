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
    var firstName: String?
    var lastName: String?
    var nickname: String?
    var birthdate: Date?
    var phoneNumbers: [String]?
    var emailAddresses: [String]?
    var address: String?
    var photoURL: String?
    var lastContacted: Date?
    var notes: String?

    @ServerTimestamp var createdAt: Timestamp?
    var updatedAt: Timestamp
}
