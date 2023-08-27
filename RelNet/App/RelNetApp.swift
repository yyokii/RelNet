//
//  RelNetApp.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/24.
//

import SwiftUI

import ComposableArchitecture

@main
struct RelNetApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.environment["UITesting"] == "true" {
              UITestingView()
            } else if _XCTIsTesting {
              // NB: Don't run application when testing so that it doesn't interfere with tests.
              EmptyView()
            } else {
              AppView(
                store: Store(initialState: AppFeature.State()) {
                  AppFeature()
                    ._printChanges()
                }
              )
            }
        }
    }
}

struct UITestingView: View {
  var body: some View {
    AppView(
      store: Store(initialState: AppFeature.State()) {
        AppFeature()
      }
    )
  }
}
