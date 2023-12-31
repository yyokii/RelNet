//
//  ValidatableTextField.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/12/20.
//

import SwiftUI

struct ValidatableTextField: View {
    let placeholder: String
    let text: Binding<String>
    let validationResult: Result<Void, Error>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(placeholder, text: text)
            errorText
        }
    }
}

private extension ValidatableTextField {
    @ViewBuilder
    var errorText: some View {
        switch validationResult {
        case .success:
            EmptyView()
        case let .failure(error):
            if let error = error as? LocalizedError,
               let errorText = error.recoverySuggestion,
               !errorText.isEmpty {
                Text(errorText)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
}

#if DEBUG

    struct DemoValidatedTextField: View {
        @State var text = "this is demo"
        let validator = PersonInputValidator()

        var body: some View {
            NavigationView {
                ValidatableTextField (
                    placeholder: "placeholder",
                    text: $text,
                    validationResult: validator.validate(value: text, type: .name)
                )
            }
        }
    }

    #Preview {
        DemoValidatedTextField()
    }

#endif
