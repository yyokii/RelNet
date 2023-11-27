//
//  GroupItemModifier.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/19.
//

import SwiftUI

struct GroupItemModifier: ViewModifier {
    public static let cornerRadius: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .lineLimit(1)
            .bold()
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background {
                RoundedRectangle(cornerRadius: GroupItemModifier.cornerRadius)
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

    struct GroupItemModifier_Previews: PreviewProvider {
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
