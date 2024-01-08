//
//  PersonInputValidator.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/12/17.
//

import SwiftUI

struct PersonInputValidator: Equatable {
    func validate(value: String?, type: PersonInputType) -> Result<Void, Error> {
        if type.validRange.contains(value?.count ?? 0) {
            return .success(())
        } else {
            return .failure(type.error)
        }
    }

    func isValidPerson(_ person: Person) -> Bool {
        let nameValidationResult = validate(value: person.name, type: .name)
        switch nameValidationResult {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}

extension PersonInputValidator {
    enum PersonInputType {
        static let nameValidRange: ClosedRange<Int> = 1...100
        static let otherValidRange: ClosedRange<Int> = 0...1000

        case name
        case other

        var validRange: ClosedRange<Int> {
            switch self {
            case .name:
                return Self.nameValidRange
            case .other:
                return Self.otherValidRange
            }
        }

        var error: PersonInputValidationError {
            switch self {
            case .name:
                return .invalidName
            case .other:
                return .invalidOther
            }
        }
    }
}

enum PersonInputValidationError: LocalizedError, Error {
    case invalidName
    case invalidOther

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return String(localized: "validation-range-error-message \(PersonInputValidator.PersonInputType.nameValidRange.lowerBound)~\(PersonInputValidator.PersonInputType.nameValidRange.upperBound)")
        case .invalidOther:
            return String(localized:"validation-max-count-error-message \(PersonInputValidator.PersonInputType.otherValidRange.upperBound)")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidName:
            return String(localized: "validation-range-error-message \(PersonInputValidator.PersonInputType.nameValidRange.lowerBound)~\(PersonInputValidator.PersonInputType.nameValidRange.upperBound)")
        case .invalidOther:
            return String(localized:"validation-max-count-error-message \(PersonInputValidator.PersonInputType.otherValidRange.upperBound)")
        }
    }
}
