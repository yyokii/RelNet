//
//  Person.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/24.
//

import Foundation

import FirebaseFirestore
import FirebaseFirestoreSwift

struct Person: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    var firstName: String = "" // 名
    var lastName: String = "" // 姓
    var nickname: String = ""
    var hobbies: String = ""
    var likes: String = ""
    var dislikes: String = ""
    var notes: String = ""
    private(set) var groupIDs: [String] = []

    var firstNameFurigana: String?
    var lastNameFurigana: String?
    var birthdate: Date?
    var address: String?
    var lastContacted: Date?
    @ServerTimestamp var createdAt: Timestamp?
    var updatedAt: Timestamp?

    /*
     表示優先度: full name → firstName or lastName → nickname
     */
    var name: String {
        if !firstName.isEmpty,
           !lastName.isEmpty {
            // TODO: 言語設定で変更する
            return lastName + " " + firstName
        } else if nickname.isEmpty {
            return firstName.isEmpty ? lastName : firstName
        } else {
            return nickname
        }
    }

    /**
     Returns the initial (first character) of the person's name or nickname based on certain prioritized conditions.

      - Returns:
        - The initial of `lastNameFurigana` if it exists.
        - If not, it returns the initial of `firstNameFurigana` if it exists.
        - If neither furigana is available, it checks `lastName` and `firstName`.
          - If either name contains a Kanji character as the initial, it returns "その他" (Other).
        - If only `nickname` is available:
          - If the initial of the nickname is a Kanji, number, or symbol, it returns "その他" (Other).
        - If none of the above criteria are met, it defaults to "その他" (Other).

      - Note:
        - This property gives priority to furigana over the regular name and to the last name over the first name.
        - Kanji check is based on the Unicode Han script property.
     */
    var nameInitial: String {
        let otherCategory = "その他"

        // Check furigana first as it has the highest priority
        if let lastNameFurigana = lastNameFurigana, !lastNameFurigana.isEmpty {
            return String(lastNameFurigana.prefix(1))
        } else if let firstNameFurigana = firstNameFurigana, !firstNameFurigana.isEmpty {
            return String(firstNameFurigana.prefix(1))
        }

        // If furigana is not available, check names
        let nameToUse = lastName.isEmpty ? firstName : lastName
        if !nameToUse.isEmpty {
            let initial = nameToUse.prefix(1)

            // Using regex to check if the initial is a kanji character
            if initial.range(of: "\\p{Script=Han}", options: .regularExpression) != nil {
                return otherCategory
            }

            return String(initial)
        }

        // If only nickname is available
        if !nickname.isEmpty {
            let initial = nickname.prefix(1)
            // Check for kanji, number or symbol for nickname initial
            if initial.range(of: "\\p{Script=Han}", options: .regularExpression) != nil ||
               initial.rangeOfCharacter(from: CharacterSet.decimalDigits.union(CharacterSet.symbols)) != nil {
                return otherCategory
            }

            return String(initial)
        }

        // If no suitable name or nickname is found
        return otherCategory
    }
}

extension Person {
    static let mock = Self (
        id: UUID().uuidString,
        firstName: "DemoFirst",
        lastName: "DemoLast",
        nickname: "Nick",
        hobbies: "sanpo",
        likes: "soba",
        dislikes: "no love all",
        notes: "this is note",
        groupIDs: ["id-1"],
        birthdate: Date(),
        address: "tokyo",
        lastContacted: Date()
    )

    static let mock2 = Self (
        id: UUID().uuidString,
        firstName: "DemoFirst2",
        lastName: "DemoLast2",
        nickname: "Nick2",
        hobbies: "sanpo",
        likes: "soba",
        dislikes: "no love all",
        notes: "this is note",
        groupIDs: ["id-2"],
        birthdate: Date(),
        address: "tokyo",
        lastContacted: Date()
    )

    static let mock3 = Self (
        id: UUID().uuidString,
        firstName: "DemoFirst3",
        lastName: "DemoLast3",
        nickname: "Nick3",
        hobbies: "sanpo",
        likes: "soba",
        dislikes: "no love all",
        notes: "this is note",
        groupIDs: ["id-3"],
        birthdate: Date(),
        address: "tokyo",
        lastContacted: Date()
    )

    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "nickname": nickname,
            "hobbies": hobbies,
            "likes": likes,
            "dislikes": dislikes,
            "notes": notes,
            "groupIDs": groupIDs,
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
