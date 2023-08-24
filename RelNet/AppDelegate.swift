//
//  AppDelegate.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/24.
//

import UIKit

import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
  ) -> Bool {

    FirebaseApp.configure()

    return true
  }
}
