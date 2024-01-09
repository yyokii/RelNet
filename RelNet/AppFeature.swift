//
//  AppFeature.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/27.
//

import ComposableArchitecture
import SwiftUI
import _AuthenticationServices_SwiftUI

@Reducer
struct AppFeature {
    struct State: Equatable {
        var appUser: AppUser?
        var isLoading: Bool = true
        var login: Login.State = .init()
    }

    enum Action: Equatable {
        case onAppear
        case task

        case listenAuthStateResponse(TaskResult<AppUser?>)

        case login(Login.Action)
    }

    @Dependency(\.authenticationClient) private var authenticationClient

    var body: some ReducerOf<Self> {
        Scope(state: \.login, action: \.login) {
            Login()
        }
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                return .none

            case .task:
                state.isLoading = true
                return .run { send in
                    for try await result in try await self.authenticationClient.listenAuthState() {
                        await send(.listenAuthStateResponse(.success(result)))
                    }
                } catch: { error, send in
                    await send(.listenAuthStateResponse(.failure(error)))
                }

            case let .listenAuthStateResponse(.success(user)):
                state.isLoading = false
                state.appUser = user
                return .none

            case let .listenAuthStateResponse(.failure(error)):
                state.isLoading = false
                print(error.localizedDescription)
                return .none

            case let .login(.delegate(.userUpdated(user))):
                state.appUser = user
                return .none

            case .login:
                return .none
            }
        }
    }
}

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        WithViewStore(self.store, observe: { $0 }, send: { $0 }) { viewStore in
            VStack {
                if viewStore.appUser != nil {
                    NavigationStack {
                        MainView(store: Store(initialState: Main.State()) { Main() })
                    }
                } else {
                    if viewStore.isLoading {
                        ProgressView()
                    } else {
                        NavigationView {
                            LoginView(
                                store: self.store.scope(
                                    state: \.login,
                                    action: AppFeature.Action.login
                                )
                            )
                        }
                    }
                }
            }
            .task { await viewStore.send(.task).finish() }
        }
    }
}

#if DEBUG

    #Preview("light") {
        NavigationView {
            AppView(
                store: Store(initialState: AppFeature.State()) {
                    AppFeature()
                } withDependencies: {
                    $0.authenticationClient.listenAuthState = {
                        AsyncThrowingStream { continuation in
                            let user = AppUser.init()
                            continuation.yield(user)
                            continuation.finish()
                        }
                    }
                }
            )
        }
        .environment(\.colorScheme, .light)
    }

    #Preview("dark") {
        NavigationView {
            AppView(
                store: Store(initialState: AppFeature.State()) {
                    AppFeature()
                } withDependencies: {
                    $0.authenticationClient.listenAuthState = {
                        AsyncThrowingStream { continuation in
                            let user = AppUser.init()
                            continuation.yield(user)
                            continuation.finish()
                        }
                    }
                }
            )
        }
        .environment(\.colorScheme, .dark)
    }

#endif
