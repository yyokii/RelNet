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
        @PresentationState var alert: AlertState<Action.Alert>?
        @BindingState var isInquiryPresenting: Bool = false

        let appVersion = AppVersion.current
        var user: AppUser?

        init() {}
    }

    enum Action: BindableAction, Equatable, Sendable {
        case deleteAccountButtonTapped
        case inquiryButtonTapped
        case onAppear
        case signOutButtonTapped
        case versionButtonTapped

        case requestDeleteAccountResponse(TaskResult<VoidSuccess>)
        case signOutResponse(TaskResult<VoidSuccess>)

        case alert(PresentationAction<Alert>)
        case binding(BindingAction<State>)

        enum Alert: Equatable {
            case confirmDeleteAccount
            case confirmSignOut
        }
    }

    @Dependency(\.authenticationClient) var authenticationClient

    init() {}

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .deleteAccountButtonTapped:
                state.alert = .deleteAccount
                return .none

            case .inquiryButtonTapped:
                state.isInquiryPresenting = true
                return .none

            case .onAppear:
                let user = authenticationClient.currentUser()
                state.user = user
                return .none
            case .signOutButtonTapped:
                state.alert = .signOut
                return .none

            case .requestDeleteAccountResponse(.success):
                return .none

            case let .requestDeleteAccountResponse(.failure(error)):
                print(error.localizedDescription)
                return .none

            case .signOutResponse(.success):
                return .none

            case let .signOutResponse(.failure(error)):
                print(error.localizedDescription)
                return .none

            case .versionButtonTapped:
                UIPasteboard.general.string = state.appVersion.versionText
                return .none

            case .alert(.presented(.confirmDeleteAccount)):
                return .run { send in
                    await send(
                        .requestDeleteAccountResponse(
                            await TaskResult {
                                try await authenticationClient.requestDeleteAccount()
                            }
                        )
                    )
                }

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

            case .alert, .binding:
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
                Form {
                    Section("サポート") {
                        inquiryRow
                        versionRow
                    }

                    Section("アカウント") {
                        HStack {
                            RoundedIconAndTitle(symbolName: "person", iconColor: .teal, title: "email")
                            Spacer()
                            Text(viewStore.user?.email ?? "")
                        }

                        Button {
                            viewStore.send(.signOutButtonTapped)
                        } label: {
                            Text("サインアウト")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }

                    Button {
                        viewStore.send(.deleteAccountButtonTapped)
                    } label: {
                        Text("アカウントを削除")
                    }
                    .buttonStyle(BorderlessButtonStyle())

                }
                .navigationTitle("設定")
                .navigationBarTitleDisplayMode(.inline)
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
            .alert(store: self.store.scope(state: \.$alert, action: MyPage.Action.alert))
        }
    }

    init(store: StoreOf<MyPage>) {
        self.store = store
        self.viewStore = ViewStore(self.store, observe: { $0 })
    }
}

extension AlertState where Action == MyPage.Action.Alert {
    static let deleteAccount = Self {
        TextState("delete-account-alert-title")
    } actions: {
        ButtonState(role: .cancel) {
            TextState("cancel")
        }
        ButtonState(role: .destructive, action: .confirmDeleteAccount) {
            TextState("yes")
        }
    } message: {
        TextState("")
    }

    static let signOut = Self {
        TextState("sign-out-alert-title")
    } actions: {
        ButtonState(role: .cancel) {
            TextState("cancel")
        }
        ButtonState(role: .destructive, action: .confirmSignOut) {
            TextState("yes")
        }
    } message: {
        TextState("")
    }
}

private extension MyPageView {

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
            SafariView(url: .init(string: "https://forms.gle/M82F4pnAVKRnm6bk8")!)
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

#if DEBUG

    struct MyPageView_Previews: PreviewProvider {
        static var previews: some View {
            NavigationStack {
                MyPageView(
                    store: Store(initialState: MyPage.State()) {
                        MyPage()
                    } withDependencies: {
                        $0.authenticationClient.currentUser = {
                            return .init()
                        }
                    }
                )
            }
        }
    }

#endif
