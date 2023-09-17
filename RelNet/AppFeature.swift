//
//  AppFeature.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/27.
//

import SwiftUI

import ComposableArchitecture

struct AppFeature: Reducer {
    struct State: Equatable {
        var appUser: AppUser?
    }

    enum Action: Equatable {
        case onAppear
        case signInWithGoogleButtonTapped
        case signInWithGoogleResponse(TaskResult<AppUser>)

        // Other Action
        case task
        case listenAuthStateResponse(TaskResult<AppUser?>)
    }

    @Dependency(\.authenticationClient) private var authenticationClient

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                return .none

            case .signInWithGoogleButtonTapped:
                // TODO: 別のReducerにしたいかも
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
                return .run { send in
                    for try await result in try await self.authenticationClient.listenAuthState() {
                        await send(.listenAuthStateResponse(.success(result)))
                    }
                } catch: { error, send in
                    await send(.listenAuthStateResponse(.failure(error)))
                }

            case let .listenAuthStateResponse(.success(user)):
                state.appUser = user
                return .none

            case let .listenAuthStateResponse(.failure(error)):
                print(error.localizedDescription)
                return .none

            case let .signInWithGoogleResponse(.success(user)):
                state.appUser = user
                return .none

            case let .signInWithGoogleResponse(.failure(error)):
                print(error.localizedDescription)
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
                    VStack {
                        Text("need to signin")
                        Button {
                            viewStore.send(.signInWithGoogleButtonTapped)
                        } label: {
                            Text("sign in with google")
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
