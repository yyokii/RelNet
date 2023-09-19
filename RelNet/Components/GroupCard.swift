//
//  GroupCard.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/19.
//

import SwiftUI

struct GroupCard: View {
    let group: Group

    var body: some View {
        VStack(alignment: .leading) {
            Text(self.group.name)
                .font(.headline)
                .lineLimit(2)
        }
        .frame(width: 80, height: 80)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange)
        }
    }
}
