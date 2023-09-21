//
//  Binding+Extension.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/27.
//

import SwiftUI

extension Binding {
    func toUnwrapped<T>(defaultValue: T) -> Binding<T> where Value == Optional<T>  {
        Binding<T>(get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 })
    }
}
