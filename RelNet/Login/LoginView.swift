//
//  LoginView.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/04.
//

import ComposableArchitecture
import CryptoKit
import Dispatch
import SwiftUI
import _AuthenticationServices_SwiftUI

struct Login: Reducer, Sendable {
    struct State: Equatable {
        @PresentationState var alert: AlertState<AlertAction>?
        var isLoading: Bool = false
        var currentNonce: String?

        init() {}
    }

    enum Action: TCAFeatureAction, Equatable, Sendable {
        case view(View)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        case alert(PresentationAction<AlertAction>)

        enum View: Equatable {
            case onCompletedSignInWithApple(TaskResult<ASAuthorization>)
            case signInWithAppleButtonTapped(ASAuthorizationAppleIDRequest)
            case signInWithGoogleButtonTapped
        }

        enum InternalAction: Equatable {
            case signInWithAppleResponse(TaskResult<AppUser>)
            case signInWithGoogleResponse(TaskResult<AppUser>)
        }

        enum DelegateAction: Equatable {
            case userUpdated(AppUser)
        }
    }

    enum AlertAction: Equatable, Sendable {}

    @Dependency(\.authenticationClient) var authenticationClient

    init() {}

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .alert:
                return .none

            case let .view(viewAction):
                switch viewAction {
                case let .onCompletedSignInWithApple(result):
                    switch result {
                    case let .success(authorization):
                        return .run { [nonce = state.currentNonce] send in
                            await send(
                                .internal(
                                    .signInWithAppleResponse(
                                        await TaskResult {
                                            try await self.authenticationClient.handleSignInWithAppleResponse(
                                                authorization,
                                                nonce ?? ""
                                            )
                                        }
                                    )
                                )
                            )
                        }
                    case let .failure(error):
                        return .send(.internal(.signInWithAppleResponse(.failure(error))))
                    }
                case let .signInWithAppleButtonTapped(request):
                    state.isLoading = true
                    if let nonce = randomNonceString() {
                        state.currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    } else {
                        // TODO: show alert
                    }
                    return .none
                case .signInWithGoogleButtonTapped:
                    state.isLoading = true
                    return .run { send in
                        await send(
                            .internal(
                                .signInWithGoogleResponse(
                                    await TaskResult {
                                        try await self.authenticationClient.signInWithGoogle()
                                    }
                                )
                            )
                        )
                    }
                }
            case let .internal(internalAction):
                switch internalAction {
                case let .signInWithAppleResponse(.success(user)):
                    state.isLoading = false
                    return .send(.delegate(.userUpdated(user)))
                case let .signInWithAppleResponse(.failure(error)):
                    state.isLoading = false
                    return .none
                case let .signInWithGoogleResponse(.success(user)):
                    state.isLoading = false
                    return .send(.delegate(.userUpdated(user)))
                case let .signInWithGoogleResponse(.failure(error)):
                    state.isLoading = false
                    return .none
                }
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: /Action.alert)
    }
}

private extension Login {
    private func randomNonceString(length: Int = 32) -> String? {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard errorCode != errSecSuccess else {
            return nil
        }

        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString =
            hashedData.compactMap {
                String(format: "%02x", $0)
            }
            .joined()

        return hashString
    }
}

struct LoginView: View {
    let store: StoreOf<Login>
    @ObservedObject var viewStore: ViewStoreOf<Login>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            signInButtons
        }
        .padding(.horizontal, 24)
        .disabled(viewStore.isLoading)
        .alert(store: self.store.scope(state: \.$alert, action: Login.Action.alert))
        .navigationTitle("login-title")
    }

    init(store: StoreOf<Login>) {
        self.store = store
        self.viewStore = ViewStore(self.store, observe: { $0 })
    }
}

private extension LoginView {
    var signInButtons: some View {
        VStack(alignment: .leading, spacing: 12) {
            SignInWithAppleButton { request in
                viewStore.send(.view(.signInWithAppleButtonTapped(request)))
            } onCompletion: { result in
                viewStore.send(.view(.onCompletedSignInWithApple(.init(result))))
            }
            .frame(height: 50)

            Button {
                viewStore.send(.view(.signInWithGoogleButtonTapped))
            } label: {
                HStack(alignment: .center, spacing: 6) {
                    Image(.googleLogo)
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text("sign-in-with-google-button-title")
                        .font(.title3)
                        .foregroundStyle(Color.adaptiveBlack)
                }
                .frame(maxWidth: .infinity)

            }
            .frame(height: 50)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.gray, lineWidth: 1)
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LoginView(
                store: Store(initialState: Login.State()) {
                    Login()
                } withDependencies: { _ in
                }
            )
        }
    }
}
