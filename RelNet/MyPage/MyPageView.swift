//
//  MyPageView.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/04.
//

import SwiftUI

import ComposableArchitecture
import Dispatch

struct MyPage: Reducer, Sendable {
    struct State: Equatable {
        @PresentationState var alert: AlertState<Action.Alert>?
        var openInquiry: Bool = false

        init() {}
    }

    enum Action: Equatable, Sendable {
        case alert(PresentationAction<Alert>)
        case inquiryButtonTapped
        case signOutButtonTapped
        case signOutResponse(TaskResult<VoidSuccess>)
        case versionButtonTapped(AppVersion)

        enum Alert: Equatable {
            case confirmSignOut
        }
    }

    @Dependency(\.authenticationClient) var authenticationClient

    init() {}

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .alert(.presented(.confirmSignOut)):
                return .run { send in
                    await send(
                        .signOutResponse(
                            await TaskResult {
                                try await authenticationClient.signOut()
                            }
                        )
                    )
                }

            case .alert:
                return .none

            case .inquiryButtonTapped:
                state.openInquiry = true
                return .none

            case .signOutButtonTapped:
                state.alert = .signOut
                return .none

            case .signOutResponse(.success):
                return .none

            case let .signOutResponse(.failure(error)):
                print(error.localizedDescription)
                return .none

            case .versionButtonTapped(let appVersion):
                UIPasteboard.general.string = appVersion.versionText
                return .none
            }
        }
        .ifLet(\.$alert, action: /Action.alert)
    }
}

struct MyPageView: View {
    let store: StoreOf<MyPage>

    struct ViewState: Equatable {
        @BindingViewState var email: String
        var isActivityIndicatorVisible: Bool
        var isFormDisabled: Bool
        var isLoginButtonDisabled: Bool
        @BindingViewState var password: String
    }

    private let appVersion = AppVersion.current

    init(store: StoreOf<MyPage>) {
        self.store = store
    }

    var body: some View {
        WithViewStore(self.store, observe: { $0 }, send: { $0 }) { viewStore in
            VStack {
                topCard
                    .padding(.horizontal)
                    .padding(.vertical)

                Form {
                    Section("App") {
                        demo
                        demo
                    }

                    Section("サポート") {
                        inquiry(viewStore: viewStore)
                        version(viewStore: viewStore)
                    }

                    Section("アカウント") {
                        Button {
                            viewStore.send(.signOutButtonTapped)
                        } label: {
                            Text("サインアウト")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                .navigationTitle("Me")
            }
            .alert(store: self.store.scope(state: \.$alert, action: MyPage.Action.alert))
        }
        .navigationTitle("Login")
    }
}

extension AlertState where Action == MyPage.Action.Alert {
    static let signOut = Self {
        TextState("Sign Out")
    } actions: {
        ButtonState(role: .cancel) {
            TextState("Cancel")
        }
        ButtonState(role: .destructive, action: .confirmSignOut) {
            TextState("Yes, sign out")
        }
    } message: {
        TextState(
      """
      Sign out now?
      """
        )
    }
}

private extension MyPageView {
    var topCard: some View {
        Text("top card")
    }

    var demo: some View {
        HStack {
            RoundedIconAndTitle(symbolName: "square.stack", iconColor: .blue, title: "demo")
            Spacer()
            Text("demo")
        }
    }

    func inquiry(viewStore: ViewStore<MyPage.State, MyPage.Action>) -> some View {
        Button(action: {
            viewStore.send(.inquiryButtonTapped)
        }) {
            RoundedIconAndTitle(symbolName: "mail", iconColor: .green, title: "お問い合わせ")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented:
                viewStore.binding(
                    get: \.openInquiry,
                    send: MyPage.Action.inquiryButtonTapped
                )
        ) {
            SafariView(url: .init(string: "https://www.google.com/?hl=ja")!)
        }
    }

    func version(viewStore: ViewStore<MyPage.State, MyPage.Action>) -> some View {
        Button(action: {
            viewStore.send(.versionButtonTapped(appVersion))
        }) {
            HStack {
                RoundedIconAndTitle(symbolName: "iphone.homebutton", iconColor: .orange, title: "バージョン")
                Spacer()
                Text(appVersion.versionText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct MyPageView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MyPageView(
                store: Store(initialState: MyPage.State()) {
                    MyPage()
                } withDependencies: { _ in }
            )
        }
    }
}

