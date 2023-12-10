//
//  AppFeature.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/27.
//

import ComposableArchitecture
import SwiftUI
import _AuthenticationServices_SwiftUI

struct AppFeature: Reducer {
    struct State: Equatable {
        var appUser: AppUser?
        var isLoading: Bool = true
        var login: Login.State = .init()
    }

    enum Action: Equatable {
        case onAppear
        case signInWithGoogleButtonTapped
        case task

        case listenAuthStateResponse(TaskResult<AppUser?>)
        case signInWithGoogleResponse(TaskResult<AppUser>)

        case login(Login.Action)
    }

    @Dependency(\.authenticationClient) private var authenticationClient

    var body: some ReducerOf<Self> {
        Scope(state: \.login, action: /Action.login) {
          Login()
        }
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                return .none

            case .signInWithGoogleButtonTapped:
                state.isLoading = true
                return .run { send in
                    await send(
                        .signInWithGoogleResponse(
                            await TaskResult {
                                try await self.authenticationClient.signInWithGoogle()
                            }
                        )
                    )
                }

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

            case let .signInWithGoogleResponse(.success(user)):
                state.isLoading = false
                state.appUser = user
                return .none

            case let .signInWithGoogleResponse(.failure(error)):
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
                    TabView {
                        mainTab
                        myProfileTab
                    }
                } else {
                    if viewStore.isLoading {
                        ProgressView()
                    } else {
                        NavigationView {
                            LoginView(
                                store: self.store.scope(
                                    state: \.login,
                                    action: AppFeature.Action.login)
                            )
                        }
                    }
                }
            }
            .task { await viewStore.send(.task).finish() }
        }
    }
}

private extension AppView {
    var mainTab: some View {
        NavigationStack {
            MainView(store: Store(initialState: Main.State()) { Main() })
        }
        .tabItem {
            Label("groups", systemImage: "rectangle.3.group.fill")
        }
    }

    var myProfileTab: some View {
        NavigationStack {
            MyPageView(store: Store(initialState: MyPage.State()) { MyPage() })
        }
        .tabItem {
            Label("persons", systemImage: "person.crop.circle.fill")
        }
    }
}
