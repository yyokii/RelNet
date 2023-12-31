//
//  Person.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/24.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

/// 人を表す
///
/// プロパティについては必須項目以外は、基本的にオプショナル。
/// オプショナルとすることで、新しいプロパティを追加しても既存のデータも正常に読み取りが可能。
struct Person: Codable, Identifiable, Hashable {
    @DocumentID var id: String?

    // MARK: Basic info
    var name: String = ""
    var furigana: String?
    var nickname: String?
    var birthdate: Date?
    var address: String?
    var hobbies: String?
    var likes: String?
    var dislikes: String?
    var lastContacted: Date?
    // TODO: OrderedSet にする
    private(set) var groupIDs: [String] = []

    // MARK: Family
    var parents: String?
    var sibling: String?
    var pets: String?

    // MARK: Food
    var likeFoods: String?
    var likeSweets: String?
    var allergies: String?
    var dislikeFoods: String?

    // MARK: Music
    var likeMusicCategories: String?
    var likeArtists: String?
    var likeMusics: String?
    var playableInstruments: String?

    // MARK: Travel
    var travelCountries: String?
    var favoriteLocations: String?

    var notes: String?

    @ServerTimestamp var createdAt: Timestamp?
    var updatedAt: Timestamp?

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
        if let furigana, !furigana.isEmpty {
            return String(furigana.prefix(1))
        }

        // If furigana is not available, check names
        if !name.isEmpty {
            let initial = name.prefix(1)

            // Using regex to check if the initial is a kanji character
            if initial.range(of: "\\p{Script=Han}", options: .regularExpression) != nil {
                return otherCategory
            }

            return String(initial)
        }

        // If only nickname is available
        if let nickname, !nickname.isEmpty {
            let initial = nickname.prefix(1)
            // Check for kanji, number or symbol for nickname initial
            if initial.range(of: "\\p{Script=Han}", options: .regularExpression) != nil || initial.rangeOfCharacter(from: CharacterSet.decimalDigits.union(CharacterSet.symbols)) != nil {
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

    #if DEBUG
        static func mock(
            id: String = UUID().uuidString,
            groupIDs: [String] = ["id-1"]
        ) -> Self {
            .init(
                id: id,
                name: "name",
                furigana: "フリガナ",
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
    #endif
}
