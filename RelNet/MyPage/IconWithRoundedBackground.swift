//
//  IconWithRoundedBackground.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/04.
//

import SwiftUI

struct IconWithRoundedBackground: View {

    let systemName: String
    let backgroundColor: Color

    var body: some View {
        Image(systemName: systemName)
            .foregroundColor(.white)
            .frame(width: 30, height: 30)
            .bold()
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(backgroundColor)
            }
    }
}
