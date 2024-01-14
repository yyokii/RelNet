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
    let indexes: [String] = {
        let hiraganas = ["あ","か","さ","た","な","は","ま","や","ら","わ"]
        let alphabets = (65...90).compactMap { UnicodeScalar($0) }.map { String($0) }
        var indexes = hiraganas + alphabets
        indexes.append(String(localized: "other-category-title"))
        return indexes
    }()

    var body: some View {
        VStack {
            ForEach(indexes, id: \.self) { title in
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .foregroundColor(Color.gray.opacity(0.1))
                    .frame(width: 10, height: 10)
                    .overlay(
                        Text(title)
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    )
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
            DispatchQueue.main.async {
                print("📝 called with: \(title)")
                proxy.scrollTo(title, anchor: .top)
            }
        }
        return Rectangle().fill(Color.clear)
    }
}
