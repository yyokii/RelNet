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
        var isSignIn: Bool = false
    }

    enum Action: Equatable {
        case onAppear
        case signInWithGoogleButtonTapped
        case updateSignInState(Bool)
    }

    @Dependency(\.authenticationClient) private var authenticationClient

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                let user = authenticationClient.currentUser()
                state.isSignIn = user != nil
                return .none

            case .signInWithGoogleButtonTapped:
                // TODO: 別のReducerにしたいかも
                return .run { send in
                    let _ = try await authenticationClient.signInWithGoogle()
                    await send(.updateSignInState(true))
                } catch: { error, send in
                    await send(.updateSignInState(false))
                }

            case let .updateSignInState(isSignIn):
                state.isSignIn = isSignIn
                return .none
            }
        }
    }
}

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        WithViewStore(self.store, observe: { $0 }, send: { $0 }) { viewStore in
            if viewStore.isSignIn {
                TabView {
                    mainTab
                    myProfileTab
                }
            } else {
                Text("need to signin")
                Button {
                    viewStore.send(.signInWithGoogleButtonTapped)
                } label: {
                    Text("sign in with google")
                }
            }
        }
    }
}

private extension AppView {
    var mainTab: some View {
        NavigationStack {
            MainView(
                store: Store(initialState: Main.State()) {
                    Main()
                }
            )
        }
        .tabItem {
            Label("groups", systemImage: "rectangle.3.group.fill")
        }
    }

    var myProfileTab: some View {
        Text("this is my profile")
            .tabItem {
                Label("persons", systemImage: "person.crop.circle.fill")
            }
    }
}
