//
//  Locale+Extension.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2024/01/21.
//

import Foundation


extension Locale {
    /*
     https://qiita.com/uhooi/items/a9c9d8b923005028ce4e
     */
    static var appLanguageLocale: Locale {
        if let preferredLanguage = Locale.preferredLanguages.first {
            return Locale(identifier: preferredLanguage)
        } else {
            return Locale.current
        }
    }
}
