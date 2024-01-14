//
//  IndexList.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2024/01/14.
//

import SwiftUI

struct IndexList: View {
    @GestureState private var dragLocation: CGPoint = .zero

    let proxy: ScrollViewProxy
    let scrollTargetIndexes: [String]
    let generator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    let indexes: [String] = {
        let hiraganas = ["あ","か","さ","た","な","は","ま","や","ら","わ"]
        let alphabets = (65...90).compactMap { UnicodeScalar($0) }.map { String($0) }
        var indexes = hiraganas + alphabets
        indexes.append(String(localized: "other-category-title"))
        return indexes
    }()

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            ForEach(indexes, id: \.self) { title in
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.adaptiveBlue)
                    .background(dragObserver(title: title))
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .updating($dragLocation) { value, state, _ in
                    state = value.location
                }
        )
    }

    func dragObserver(title: String) -> some View {
        GeometryReader { geometry in
            dragObserver(geometry: geometry, title: title)
        }
    }

    func dragObserver(geometry: GeometryProxy, title: String) -> some View {
        if geometry.frame(in: .global).contains(dragLocation),
           scrollTargetIndexes.contains(title) {
            Task { @MainActor in
                generator.prepare()
                generator.impactOccurred()
                proxy.scrollTo(title, anchor: .top)
            }
        }
        return Rectangle().fill(Color.clear)
    }
}
