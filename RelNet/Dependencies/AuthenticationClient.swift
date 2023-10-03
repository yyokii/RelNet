//
//  AuthenticationClient.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/04.
//

import Foundation

import ComposableArchitecture
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

struct AuthenticationClient: Sendable {

    var currentUser: @Sendable () -> AppUser?
    var listenAuthState: @Sendable () async throws -> AsyncThrowingStream<AppUser?, Error>
    var signInWithGoogle: @Sendable () async throws -> AppUser
    var signOut: @Sendable () async throws -> Void

    init(
        currentUser: @escaping @Sendable () -> AppUser?,
        listenAuthState: @escaping @Sendable () async throws -> AsyncThrowingStream<AppUser?, Error>,
        signInWithGoogle: @escaping @Sendable () async throws -> AppUser,
        signOut: @escaping @Sendable () async throws -> Void
    ) {
        // Create Google Sign In configuration object.
        let clientID = FirebaseApp.app()!.options.clientID!
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        self.signInWithGoogle = signInWithGoogle
        self.listenAuthState = listenAuthState
        self.currentUser = currentUser
        self.signOut = signOut
    }
}

extension DependencyValues {
    var authenticationClient: AuthenticationClient {
        get { self[AuthenticationClient.self] }
        set { self[AuthenticationClient.self] = newValue }
    }
}

extension AuthenticationClient: DependencyKey {
    public static let liveValue = Self(
        currentUser: {
            let user =  Auth.auth().currentUser
            return .init(from: user)
        },
        listenAuthState: {
            AsyncThrowingStream { continuation in
                guard let user = Auth.auth().currentUser else {
                    continuation.finish(throwing: PersonClientError.notFoundUser)
                    return
                }

                let listenerHandle = Auth.auth().addStateDidChangeListener { auth, user in
                    if let user {
                        let appUser = AppUser(from: user)
                        continuation.yield(appUser)
                    } else {
                        continuation.yield(nil)
                    }
                }

                continuation.onTermination = { _ in
                    Auth.auth().removeStateDidChangeListener(listenerHandle)
                }
            }
        },
        signInWithGoogle: {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw AuthenticationClientError.notFoundClientID
            }

            let configuration = GIDConfiguration(clientID: clientID)

            guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = await windowScene.windows.first?.rootViewController else {
                throw AuthenticationClientError.notFoundRootVC
            }

            do {
                let result = try await signInOnMainThread(withPresenting: rootViewController)
                return try await authenticateUser(for: result.user)
            } catch {
                throw AuthenticationClientError.notFoundUser
            }
        },
        signOut: {
            do {
                try Auth.auth().signOut()
            } catch {
                throw AuthenticationClientError.general(error)
            }
        }
    )
}

private extension AuthenticationClient {
    private static func authenticateUser(for user: GIDGoogleUser) async throws -> AppUser {
        guard let idToken = user.idToken?.tokenString else {
            throw AuthenticationClientError.notFoundUser
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: user.accessToken.tokenString
        )

        return try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signIn(with: credential) { (result, error) in
                if let error = error {
                    print(error.localizedDescription)
                    continuation.resume(with: .failure(AuthenticationClientError.notFoundUser))
                } else {
                    guard let user = result?.user,
                          let appUser = AppUser(from: user) else {
                        continuation.resume(with: .failure(AuthenticationClientError.notFoundUser))
                        return
                    }

                    continuation.resume(with: .success(appUser))
                }
            }
        }
    }

    // TODO: signInはメインスレッドで呼び出す必要があるが、GIDSignInResultはsendableではないため、別のアクターコンテキストからMainActorへ変更することはできない。それ故に警告が発生するので呼び出し方変える必要あり（メインスレッド実行されるところで呼ぶ）。メインスレッドで実行する必要があり、そしてasync awaitでGIDSignInResultを返却しているのにそれがSendableではない、ということが問題と思われる
    @MainActor
    private static func signInOnMainThread(withPresenting rootViewController: UIViewController) async throws -> GIDSignInResult {
        try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
    }
}

struct AppUser: Equatable {
    let uid: String
    let name: String?
    let photoURL: URL?

    init?(from firebaseUser: User?) {
        if let firebaseUser {
            self.uid = firebaseUser.uid
            self.name = firebaseUser.displayName
            self.photoURL = firebaseUser.photoURL
        } else {
            return nil
        }
    }
}

enum AuthenticationClientError: LocalizedError, Sendable {
    case general(Error?)
    case invalidUserPassword
    case invalidIntermediateToken
    case notFoundClientID
    case notFoundRootVC
    case notFoundUser

    var errorDescription: String? {
        switch self {
        case let .general(error):
            return "failed. \(String(describing: error?.localizedDescription))"
        case .invalidUserPassword:
            return "Unknown user or invalid password."
        case .invalidIntermediateToken:
            return "404!! What happened to your token there bud?!?!"
        case .notFoundClientID:
            return "Not found clientID"
        case .notFoundRootVC:
            return "Not found root VC"
        case .notFoundUser:
            return "Not found user"
        }
    }
}
