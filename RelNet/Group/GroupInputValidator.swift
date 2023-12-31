//
//  GroupInputValidator.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/12/20.
//

import SwiftUI

struct GroupInputValidator: Equatable {
    func validate(value: String?, type: GroupInputType) -> Result<Void, Error> {

        if type.validRange.contains(value?.count ?? 0) {
            return .success(())
        } else {
            return .failure(type.error)
        }
    }

    func isValidGroup(_ group: Group) -> Bool {
        let nameValidationResult = validate(value: group.name, type: .name)
        switch nameValidationResult {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}

extension GroupInputValidator {
    enum GroupInputType {
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

        var error: GroupInputValidationError {
            switch self {
            case .name:
                return .invalidName
            case .other:
                return .invalidOther
            }
        }
    }
}

enum GroupInputValidationError: LocalizedError, Error {
    case invalidName
    case invalidOther

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "\(GroupInputValidator.GroupInputType.nameValidRange.lowerBound)文字以上\(GroupInputValidator.GroupInputType.nameValidRange.upperBound)文字以下で入力してください"
        case .invalidOther:
            return "\(GroupInputValidator.GroupInputType.nameValidRange.upperBound)文字以下で入力してください"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidName:
            return "\(GroupInputValidator.GroupInputType.nameValidRange.lowerBound)文字以上\(GroupInputValidator.GroupInputType.nameValidRange.upperBound)文字以下で入力してください"
        case .invalidOther:
            return "\(GroupInputValidator.GroupInputType.nameValidRange.upperBound)文字以下で入力してください"
        }
    }
}
