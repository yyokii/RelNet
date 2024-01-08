//
//  ContentTypeSegmentedPicker.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2024/01/03.
//

import SwiftUI

struct ContentTypeSegmentedPicker: View {
    @Binding var selectedContentType: ContentType

    var body: some View {
        Picker("", selection: $selectedContentType) {
            ForEach(ContentType.allCases, id: \.self) { option in
                Text(option.name)
            }
        }
        .pickerStyle(.segmented)
    }
}

extension ContentTypeSegmentedPicker {
    enum ContentType: CaseIterable {
        case list
        case note

        var name: String {
            switch self {
            case .list:
                return String(localized: "list-section-title")
            case .note:
                return String(localized: "note-section-title")
            }
        }
    }
}
