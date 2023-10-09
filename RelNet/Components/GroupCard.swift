//
//  GroupCard.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/19.
//

import SwiftUI

private struct GroupItemModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .lineLimit(1)
            .bold()
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.secondary)
                    .opacity(0.2)
            }
    }
}

extension Text {
    func groupItemText() -> some View {
        self
            .modifier(GroupItemModifier())
    }
}

#if DEBUG

struct GroupCard_Previews: PreviewProvider {
    static var content: some View {
        NavigationView {
            Text("group name")
                .groupItemText()
        }
    }

    static var previews: some View {
        content
            .environment(\.colorScheme, .light)

        content
            .environment(\.colorScheme, .dark)
    }
}

#endif
