//
//  Color.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/22.
//

import SwiftUI

extension Color {

    /// lightモードの場合に、白を設定し且つカラーテーマに対応する
    public static let adaptiveWhite = Self {
        $0.userInterfaceStyle == .dark ? .black : .white
    }

    /// lightモードの場合に、黒を設定し且つカラーテーマに対応する
    public static let adaptiveBlack = Self {
        $0.userInterfaceStyle == .dark ? .white : .black
    }

    /*
     白、黒 + アクセント色で基本的に表現する
     */
    public static let appAccent = Self { _ in
        .red
    }

    public static func hex(_ hex: UInt) -> Self {
        Self(
            red: Double((hex & 0xff0000) >> 16) / 255,
            green: Double((hex & 0x00ff00) >> 8) / 255,
            blue: Double(hex & 0x0000ff) / 255,
            opacity: 1
        )
    }
}

#if canImport(UIKit)

    import UIKit

    extension Color {

        public init(dynamicProvider: @escaping (UITraitCollection) -> Color) {
            self = Self(UIColor { UIColor(dynamicProvider($0)) })
        }

        public static let placeholderGray = Color(UIColor.placeholderText)
    }

#endif

#if DEBUG

    struct DemoColorView_Previews: PreviewProvider {

        static var content: some View {
            NavigationStack {
                VStack {
                    HStack {
                        VStack {
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundColor(.adaptiveBlack)
                            Text("adaptiveBlack")
                        }

                        VStack {
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundColor(.adaptiveWhite)
                            Text("adaptiveWhite")
                        }
                    }

                    VStack {
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundColor(.placeholderGray)
                        Text("placeholderGray")
                    }

                    HStack {
                        VStack {
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundColor(.appAccent)
                            Text("appAccent")
                        }
                    }

                }
                .shadow(radius: 10)
                .padding(.horizontal)
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
