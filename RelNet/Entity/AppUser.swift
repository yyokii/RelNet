//
//  AppUser.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/12/14.
//

import FirebaseAuth
import Foundation

struct AppUser: Equatable {
    let uid: String
    let email: String?
    let name: String?
    let photoURL: URL?

    init?(from firebaseUser: User?) {
        if let firebaseUser {
            self.uid = firebaseUser.uid
            self.email = firebaseUser.email
            self.name = firebaseUser.displayName
            self.photoURL = firebaseUser.photoURL
        } else {
            return nil
        }
    }
}

#if DEBUG

    extension AppUser {
        init(
            uid: String = UUID().uuidString,
            email: String = "emial@email",
            name: String = "demo name",
            photoURL: URL? = URL(string: "https://picsum.photos/200")!
        ) {
            self.uid = uid
            self.email = email
            self.name = name
            self.photoURL = photoURL
        }
    }

#endif
