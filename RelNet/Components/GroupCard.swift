//
//  GroupCard.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/19.
//

import SwiftUI

struct GroupCard: View {
    static let size: CGSize = .init(width: 120, height: 120)

    let group: Group

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            // TODO: 絵文字設定できるようにする？
            Text("🦄")
                .font(.system(size: 32))
            Text(self.group.name)
                .font(.headline)
                .lineLimit(2)
                .foregroundColor(.adaptiveWhite)
                .bold()
        }
        .padding(8)
        .frame(
            width: GroupCard.size.width,
            height: GroupCard.size.height
        )
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.adaptiveBlack)
        }
    }
}

#if DEBUG

struct GroupCard_Previews: PreviewProvider {
    static var previews: some View {
        GroupCard(group: .mock)
    }
}

#endif
