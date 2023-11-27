//
//  Person.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/24.
//

import Foundation

import FirebaseFirestore
import FirebaseFirestoreSwift

/// 人を表す
///
/// 空の初期値を持ち、Dateなどの「空」を表現できないものについてのみオプショナルとしている。
struct Person: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?

    // MARK: Basic info
    // TODO: 名前は性名で分けると多言語で大変なのでnameにする
    var firstName: String = "" // 名
    var lastName: String = "" // 姓
    var firstNameFurigana: String?
    var lastNameFurigana: String?
    var nickname: String = ""
    var birthdate: Date?
    var address: String = ""
    var hobbies: String = ""
    var likes: String = ""
    var dislikes: String = ""
    var lastContacted: Date?
    // TODO: OrderedSet にする
    private(set) var groupIDs: [String] = []

    // MARK: Family
    var parents: String = ""
    var sibling: String = ""
    var pets: String = ""

    // MARK: Food
    var likeFoods: String = ""
    var likeSweets: String = ""
    var allergies: String = ""
    var dislikeFoods: String = ""

    // MARK: Music
    var likeMusicCategories: String = ""
    var likeArtists: String = ""
    var likeMusics: String = ""
    var playableInstruments: String = ""

    // MARK: Travel
    var travelCountries: String = ""
    var favoriteLocations: String = ""

    var notes: String = ""

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

    mutating func updateGroupID(_ id: String) {
        if !groupIDs.contains(id) {
            groupIDs.append(id)
        } else {
            groupIDs.removeAll { $0 == id }
        }
    }
}

extension Person {
    static func mock(
        id: String = UUID().uuidString,
        groupIDs: [String] = ["id-1"]
    ) -> Self {
        .init(
            id: id,
            firstName: "first",
            lastName: "last",
            firstNameFurigana: "ファースト",
            lastNameFurigana: "ラスト",
            nickname: "nick",
            birthdate: Date(),
            address: "東京",
            hobbies: "散歩",
            likes: "蕎麦",
            dislikes: "no",
            lastContacted: Date(),
            groupIDs: groupIDs,
            parents: "parents",
            sibling: "sibling",
            pets: "猫",
            likeFoods: "蕎麦",
            likeSweets: "モンブラン",
            allergies: "なし",
            dislikeFoods: "なし",
            likeMusicCategories: "なんでも",
            likeArtists: "たくさん",
            likeMusics: "たくさん",
            playableInstruments: "ピアノ",
            travelCountries: "オーストラリア、ニュージーランド",
            favoriteLocations: "ニュージーランド",
            notes: "this is note"
        )
    }
}
