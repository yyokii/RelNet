//
//  MyPageView.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/04.
//

import ComposableArchitecture
import Dispatch
import SwiftUI

struct MyPage: Reducer, Sendable {
    struct State: Equatable {
        let appVersion = AppVersion.current

        @PresentationState var alert: AlertState<Action.Alert>?

        @BindingState var isInquiryPresenting: Bool = false

        init() {}
    }

    enum Action: BindableAction, Equatable, Sendable {
        case alert(PresentationAction<Alert>)
        case inquiryButtonTapped
        case signOutButtonTapped
        case signOutResponse(TaskResult<VoidSuccess>)
        case versionButtonTapped

        case binding(BindingAction<State>)

        enum Alert: Equatable {
            case confirmSignOut
        }
    }

    @Dependency(\.authenticationClient) var authenticationClient

    init() {}

    var body: some Reducer<State, Action> {
        BindingReducer()
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
                state.isInquiryPresenting = true
                return .none

            case .signOutButtonTapped:
                state.alert = .signOut
                return .none

            case .signOutResponse(.success):
                return .none

            case let .signOutResponse(.failure(error)):
                print(error.localizedDescription)
                return .none

            case .versionButtonTapped:
                UIPasteboard.general.string = state.appVersion.versionText
                return .none

            case .binding:
                return .none
            }
        }
        .ifLet(\.$alert, action: /Action.alert)
    }
}

struct MyPageView: View {
    let store: StoreOf<MyPage>
    @ObservedObject var viewStore: ViewStoreOf<MyPage>

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
                        inquiryRow
                        versionRow
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

    init(store: StoreOf<MyPage>) {
        self.store = store
        self.viewStore = ViewStore(self.store, observe: { $0 })
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

    var inquiryRow: some View {
        Button(action: {
            viewStore.send(.inquiryButtonTapped)
        }) {
            RoundedIconAndTitle(symbolName: "mail", iconColor: .green, title: "お問い合わせ")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(
            isPresented: viewStore.$isInquiryPresenting
        ) {
            SafariView(url: .init(string: "https://www.google.com/?hl=ja")!)
        }
    }

    var versionRow: some View {
        Button(action: {
            viewStore.send(.versionButtonTapped)
        }) {
            HStack {
                RoundedIconAndTitle(symbolName: "iphone.homebutton", iconColor: .orange, title: "バージョン")
                Spacer()
                Text(viewStore.appVersion.versionText)
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
                } withDependencies: { _ in
                }
            )
        }
    }
}
