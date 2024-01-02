//
//  SortedPersonsView.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/21.
//

import IdentifiedCollections
import OrderedCollections
import SwiftUI

struct SortedPersonsView: View {
    let persons: IdentifiedArrayOf<Person>
    let onTapPerson: (Person) -> Void

    private var sortedPersons: OrderedDictionary<String, [Person]> {
        var dict: OrderedDictionary<String, [Person]> = [:]
        let otherCategory = String(localized: "other-category-title")

        // 初期値の設定
        for person in persons {
            let initial = person.nameInitial
            dict[initial, default: []].append(person)
        }

        // 辞書をソートして再構築
        let sortedDict = dict.sorted { customSortCriteria(key1: $0.key, key2: $1.key) }
        return OrderedDictionary(uniqueKeysWithValues: sortedDict)

        func customSortCriteria(key1: String, key2: String) -> Bool {
            if key1 == otherCategory { return false }
            if key2 == otherCategory { return true }

            let isKey1Hiragana = isHiragana(key1)
            let isKey2Hiragana = isHiragana(key2)

            if isKey1Hiragana && !isKey2Hiragana {
                return true
            } else if !isKey1Hiragana && isKey2Hiragana {
                return false
            }

            return key1 < key2
        }

        func isHiragana(_ s: String) -> Bool {
            return s.range(of: "^[ぁ-ん]+$", options: .regularExpression) != nil
        }
    }


    var body: some View {
        if persons.isEmpty {
            Text("empty-persons-message")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
                .frame(height: 160)
                .frame(maxWidth: .infinity)
        } else {
            LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders]) {
                ForEach(sortedPersons.keys, id: \.self) { key in
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(sortedPersons[key]!, id: \.self) { person in
                                Button {
                                    onTapPerson(person)
                                } label: {
                                    Text(person.name)
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }
                        }
                    } header: {
                        HStack(alignment: .center, spacing: 0) {
                            Text(key)
                                .font(.headline)
                                .foregroundColor(.adaptiveWhite)
                                .frame(width: 16, height: 16)
                                .padding(8)
                                .background {
                                    Circle()
                                        .fill(Color.adaptiveBlack)
                                }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background {
                            Color.adaptiveWhite
                        }
                    }
                }
            }
        }
    }

    func getSections(contacts: [String]) -> [Dictionary<String, [String]>.Element] {
        let grouped = Dictionary(grouping: contacts, by: { String($0.prefix(1)) })
        return grouped.sorted { $0.key < $1.key }
    }
}

#if DEBUG

    var SortedPersonsView_Preview: some View {
        NavigationView {
            VStack {
                SortedPersonsView(
                    persons: [],
                    onTapPerson: { person in
                        print("\(person.name) is tapped")
                    }
                )

                Divider()

                SortedPersonsView(
                    persons: [.mock(id: "id-1"), .mock(id: "id-1-2"), .mock(id: "id-2"), .mock(id: "id-3")],
                    onTapPerson: { person in
                        print("\(person.name) is tapped")
                    }
                )
            }
            .padding()
        }
    }

    #Preview("light") {
        SortedPersonsView_Preview
            .environment(\.colorScheme, .light)
    }

    #Preview("dark") {
        SortedPersonsView_Preview
            .environment(\.colorScheme, .dark)
    }

#endif
