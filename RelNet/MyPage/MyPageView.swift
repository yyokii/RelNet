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
        var user: AppUser?

        @PresentationState var alert: AlertState<Action.Alert>?
        @BindingState var isInquiryPresenting: Bool = false

        init() {}
    }

    enum Action: BindableAction, Equatable, Sendable {
        case alert(PresentationAction<Alert>)
        case inquiryButtonTapped
        case onAppear
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

            case .onAppear:
                let user = authenticationClient.currentUser()
                state.user = user
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
