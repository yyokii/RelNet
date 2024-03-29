//
//  SafariView.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/04.
//

import SafariServices
import SwiftUI

public struct SafariView: UIViewControllerRepresentable {

    private let url: URL
    private let config: SFSafariViewController.Configuration

    public init(url: URL, config: SFSafariViewController.Configuration = .init()) {
        self.url = url
        self.config = config
    }

    public func makeUIViewController(context: Context) -> some SFSafariViewController {
        let safariViewController = SFSafariViewController(url: url, configuration: config)
        return safariViewController
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
