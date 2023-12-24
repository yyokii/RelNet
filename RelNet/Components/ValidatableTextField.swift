//
//  ValidatableTextField.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/12/20.
//

import SwiftUI

struct ValidatableTextField: View {
    let placeholder: String
    let validatable: Validatable

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(placeholder, text: validatable.binding)
            errorText
        }
    }
}

private extension ValidatableTextField {
    var errorString: String {
        var errorString = ""
        do {
            try validatable.validate()
        } catch {
            if let error = error as? LocalizedError {
                errorString = error.recoverySuggestion ?? ""
            }
        }
        return errorString
    }

    @ViewBuilder
    var errorText: some View {
        if !errorString.isEmpty {
            Text(errorString)
                .foregroundColor(.red)
                .font(.caption)
        }
    }
}

#if DEBUG

    struct DemoValidatedTextField: View {
        @State var text = "this is demo"

        var body: some View {
            NavigationView {
                ValidatableTextField(
                    placeholder: "placeholder",
                    validatable: PersonInputType.name($text)
                )
            }
        }
    }

    #Preview {
        DemoValidatedTextField()
    }

#endif
