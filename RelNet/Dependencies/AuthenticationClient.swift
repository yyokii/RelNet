//
//  AuthenticationClient.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/04.
//

import AuthenticationServices
import ComposableArchitecture
import CryptoKit
import FirebaseAuth
import FirebaseCore
import Foundation
import GoogleSignIn

struct AuthenticationClient: Sendable {

    var currentUser: @Sendable () -> AppUser?
    var handleSignInWithAppleResponse: @Sendable (_ authorization: ASAuthorization, _ nonce: String) async throws -> AppUser
    var listenAuthState: @Sendable () async throws -> AsyncThrowingStream<AppUser?, Error>
    var signInWithGoogle: @Sendable () async throws -> AppUser
    var signOut: @Sendable () async throws -> Void

    init(
        currentUser: @escaping @Sendable () -> AppUser?,
        handleSignInWithAppleResponse: @escaping @Sendable (_ authorization: ASAuthorization, _ nonce: String) async throws -> AppUser,
        listenAuthState: @escaping @Sendable () async throws -> AsyncThrowingStream<AppUser?, Error>,
        signInWithGoogle: @escaping @Sendable () async throws -> AppUser,
        signOut: @escaping @Sendable () async throws -> Void
    ) {
        // Create Google Sign In configuration object.
        let clientID = FirebaseApp.app()!.options.clientID!
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        self.currentUser = currentUser
        self.handleSignInWithAppleResponse = handleSignInWithAppleResponse
        self.listenAuthState = listenAuthState
        self.signInWithGoogle = signInWithGoogle
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
            let user = Auth.auth().currentUser
            return .init(from: user)
        },
        handleSignInWithAppleResponse: { authorization, currentNonce in
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let appleIDToken = appleIDCredential.identityToken,
                let idTokenString = String(data: appleIDToken, encoding: .utf8)
            else {
                throw AuthenticationClientError.notFoundIdToken
            }
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: currentNonce)
            return try await signIn(with: credential)
        },
        listenAuthState: {
            AsyncThrowingStream { continuation in
                let listenerHandle = Auth.auth()
                    .addStateDidChangeListener { auth, user in
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
                let rootViewController = await windowScene.windows.first?.rootViewController
            else {
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
            throw AuthenticationClientError.notFoundIdToken
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: user.accessToken.tokenString
        )

        return try await signIn(with: credential)
    }

    private static func signIn(with credential: AuthCredential) async throws -> AppUser {
        try await withCheckedThrowingContinuation { continuation in
            Auth.auth()
                .signIn(with: credential) { (result, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        continuation.resume(with: .failure(AuthenticationClientError.notFoundUser))
                    } else {
                        guard let user = result?.user,
                            let appUser = AppUser(from: user)
                        else {
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

enum AuthenticationClientError: LocalizedError, Sendable {
    case general(Error?)
    case notFoundClientID
    case notFoundIdToken
    case notFoundRootVC
    case notFoundUser

    var errorDescription: String? {
        switch self {
        case let .general(error):
            return "failed. \(String(describing: error?.localizedDescription))"
        case .notFoundClientID:
            return "Not found clientID"
        case .notFoundIdToken:
            return "Not found id token"
        case .notFoundRootVC:
            return "Not found root VC"
        case .notFoundUser:
            return "Not found user"
        }
    }
}
