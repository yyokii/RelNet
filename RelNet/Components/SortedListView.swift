//
//  SortedPersonsView.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/21.
//

import SwiftUI

struct SortedPersonsView: View {
    let sortedItems: Dictionary<String, [Person]>
    let onTapPerson: (Person) -> Void

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(sortedItems.keys.sorted(), id: \.self) { key in
                VStack(alignment: .leading) {
                    Text(key)
                        .foregroundColor(.adaptiveWhite)
                        .padding(8)
                        .background {
                            Circle()
                                .fill(Color.adaptiveBlack)
                        }

                    LazyVStack(alignment: .leading, spacing: 8) {
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

    func getSections(contacts: [String]) -> [Dictionary<String, [String]>.Element] {
        let grouped = Dictionary(grouping: contacts, by: { String($0.prefix(1)) })
        return grouped.sorted { $0.key < $1.key }
    }
}

#if DEBUG

struct SortedPersonsView_Previews: PreviewProvider {
    static var previews: some View {
        SortedPersonsView(
            sortedItems: ["あ": [.mock], "い": [.mock2, .mock3]],
            onTapPerson: { person in
                print("\(person.name) is tapped")
            }
        )
    }
}

#endif
