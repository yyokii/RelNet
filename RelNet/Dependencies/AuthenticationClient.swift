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
    var currentUser: @Sendable () -> User?
    var signInWithGoogle: @Sendable () async throws -> User

    init(
        currentUser: @escaping @Sendable () -> User?,
        signInWithGoogle: @escaping @Sendable () async throws -> User
    ) {
        // Create Google Sign In configuration object.
        let clientID = FirebaseApp.app()!.options.clientID!
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        self.signInWithGoogle = signInWithGoogle
        self.currentUser = currentUser
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
            Auth.auth().currentUser
        },
        signInWithGoogle: {
            if GIDSignIn.sharedInstance.hasPreviousSignIn() {
                do {
                    let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
                    return try await authenticateUser(for: user)
                } catch {
                    throw AuthenticationClientError.notFoundUser
                }
            } else {
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
            }
        }
    )
}

private extension AuthenticationClient {
    private static func authenticateUser(for user: GIDGoogleUser) async throws -> User {
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
                    continuation.resume(with: .success(result!.user))
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

struct LoginRequest: Sendable {
    public var email: String
    public var password: String

    public init(
        email: String,
        password: String
    ) {
        self.email = email
        self.password = password
    }
}

struct AuthenticationResponse: Equatable, Sendable {
    public var token: String

    public init(
        token: String
    ) {
        self.token = token
    }
}

enum AuthenticationClientError: Equatable, LocalizedError, Sendable {
    case invalidUserPassword
    case invalidIntermediateToken
    case notFoundClientID
    case notFoundRootVC
    case notFoundUser

    var errorDescription: String? {
        switch self {
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
