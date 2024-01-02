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

    /// The initial character of `furigana` or `name` in uppercase.
    /// If the initial character is a Katakana, it returns the corresponding Hiragana character in uppercase.
    /// Returns a localized "other category" string if no suitable initial character is found, or if the initial character is a Kanji.
    var nameInitial: String {
        let otherCategory = String(localized: "other-category-title")
        var nameOrFurigana: String?

        // Determine the initial character based on priority
        if let furigana, !furigana.isEmpty {
            nameOrFurigana = furigana
        } else if !name.isEmpty, name.range(of: "\\p{Script=Han}", options: .regularExpression) == nil {
            nameOrFurigana = name
        }

        // If a name or furigana is available
        if let firstChar = nameOrFurigana?.prefix(1) {
            // Convert Katakana to Hiragana if necessary
            if let hiraganaChar = String(firstChar).applyingTransform(.hiraganaToKatakana, reverse: true) {
                return hiraganaChar.uppercased()
            }
            return String(firstChar).uppercased()
        }

        // If no suitable name or furigana is found, return the default category
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
