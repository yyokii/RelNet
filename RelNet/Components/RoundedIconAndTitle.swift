//
//  RoundedIconAndTitle.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/10/05.
//

import SwiftUI

struct RoundedIconAndTitle: View {
    let symbolName: String
    let iconColor: Color
    let title: String

    var body: some View {
        HStack {
            Image(systemName: symbolName)
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .bold()
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(iconColor)
                }
            Text(title)
                .font(.system(size: 14))
        }
    }
}
