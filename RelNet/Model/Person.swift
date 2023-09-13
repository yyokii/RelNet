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
    var imageURL: String?
    var lastContacted: Date?
    var notes: String = ""

    @ServerTimestamp var createdAt: Timestamp?
    var updatedAt: Timestamp?

    var name: String {
        let firstName = firstName ?? ""
        let lastName = lastName ?? ""

        if let nickname,
           !nickname.isEmpty {
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
        phoneNumbers: ["00012341234"],
        emailAddresses: ["demo@demomail.com"],
        address: "Japan",
        imageURL: "https://picsum.photos/200",
        lastContacted: Date(),
        notes: "this is note."
    )
}
