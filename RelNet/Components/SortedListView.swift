//
//  SortedPersonsView.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/21.
//

import SwiftUI

struct SortedPersonsView: View {
    let sortedItems: [String: [Person]]
    let onTapPerson: (Person) -> Void

    var body: some View {
        if sortedItems.isEmpty {
            Text("empty-persons-message")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
                .frame(height: 160)
                .frame(maxWidth: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 32) {
                ForEach(sortedItems.keys.sorted(), id: \.self) { key in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(key)
                            .font(.headline)
                            .foregroundColor(.adaptiveWhite)
                            .frame(width: 16, height: 16)
                            .padding(8)
                            .background {
                                Circle()
                                    .fill(Color.adaptiveBlack)
                            }

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(sortedItems[key]!, id: \.self) { person in
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
                    sortedItems: [:],
                    onTapPerson: { person in
                        print("\(person.name) is tapped")
                    }
                )

                Divider()

                SortedPersonsView(
                    sortedItems: [
                        "A": [.mock(id: "id-1"), .mock(id: "id-1-2")],
                        "T": [.mock(id: "id-2")],
                        "あ": [.mock(id: "id-3")]
                    ],
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
