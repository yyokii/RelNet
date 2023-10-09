//
//  Button+Extensions.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/10/10.
//

import SwiftUI

func HapticButton<Action: View>(
    action: @escaping () -> Void,
    @ViewBuilder label: () -> Action
) -> some View {
    Button(
        action: {
            let impactMed = UIImpactFeedbackGenerator(style: .light)
            impactMed.impactOccurred()
            action()
        },
        label: label
    )
}
