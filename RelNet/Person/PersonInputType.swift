//
//  PersonInputType.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/12/17.
//

import SwiftUI

protocol Validatable {
    var binding: Binding<String> { get }
    func validate() throws
}

enum PersonInputType: Validatable {
    case name(Binding<String>)
    case other(Binding<String>)

    var binding: Binding<String> {
        switch self {
        case .name(let binding), .other(let binding):
            return binding
        }
    }

    var validRange: ClosedRange<Int> {
        switch self {
        case .name:
            return Self.nameValidRange
        case .other:
            return Self.otherValidRange
        }
    }

    func validate() throws {
        switch self {
        case .name(let name):
            guard validRange.contains(name.wrappedValue.count) else { throw PersonInputValidationError.invalidName }
        case .other(let other):
            guard validRange.contains(other.wrappedValue.count) else { throw PersonInputValidationError.invalidOther }
        }
    }
}

extension PersonInputType {
    static let nameValidRange: ClosedRange<Int> = 1...100
    static let otherValidRange: ClosedRange<Int> = 0...1000
}

enum PersonInputValidationError: LocalizedError, Error {
    case invalidName
    case invalidOther

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "\(PersonInputType.nameValidRange.lowerBound)文字以上\(PersonInputType.nameValidRange.upperBound)文字以下で入力してください"
        case .invalidOther:
            return "\(PersonInputType.nameValidRange.upperBound)文字以下で入力してください"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidName:
            return "\(PersonInputType.nameValidRange.lowerBound)文字以上\(PersonInputType.nameValidRange.upperBound)文字以下で入力してください"
        case .invalidOther:
            return "\(PersonInputType.nameValidRange.upperBound)文字以下で入力してください"
        }
    }
}
