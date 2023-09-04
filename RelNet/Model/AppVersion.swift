//
//  AppVersion.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/05.
//

import Foundation

struct AppVersion: Equatable {
    let productVersion: String
    let buildNumber: String

    var versionText: String {
        "\(productVersion)(\(buildNumber))"
    }

    static let current = AppVersion(
        productVersion: Bundle.main.cfBundleShortVersionString,
        buildNumber: Bundle.main.cfBundleVersion
    )
}

private extension Bundle {
    var cfBundleShortVersionString: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var cfBundleVersion: String {
        infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
}

