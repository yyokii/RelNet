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
        @PresentationState var alert: AlertState<AlertAction>?
        var openInquiry: Bool = false

        init() {}
    }

    enum Action: Equatable, Sendable {
        case alert(PresentationAction<AlertAction>)
        case inquiryTapped
        case versionTapped(AppVersion)
    }

    enum AlertAction: Equatable, Sendable {}

    @Dependency(\.authenticationClient) var authenticationClient

    init() {}

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .alert:
                return .none

            case .inquiryTapped:
                state.openInquiry = true
                return .none
            case .versionTapped(let appVersion):
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
                }
                .navigationTitle("アプリについて")
            }
            .alert(store: self.store.scope(state: \.$alert, action: MyPage.Action.alert))
        }
        .navigationTitle("Login")
    }
}

private extension MyPageView {
    var topCard: some View {
        Text("top card")
    }

    func rowTitle(symbolName: String, iconColor: Color, title: String) -> some View {
        HStack {
            IconWithRoundedBackground(
                systemName: symbolName,
                backgroundColor: iconColor
            )
            Text(title)
                .font(.system(size: 14))
        }
    }

    var demo: some View {
        HStack {
            rowTitle(symbolName: "square.stack", iconColor: .blue, title: "demo")
            Spacer()
            Text("demo")
        }
    }

    func inquiry(viewStore: ViewStore<MyPage.State, MyPage.Action>) -> some View {
        Button(action: {
            viewStore.send(.inquiryTapped)
        }) {
            rowTitle(symbolName: "mail", iconColor: .green, title: "お問い合わせ")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented:
                viewStore.binding(
                    get: \.openInquiry,
                    send: MyPage.Action.inquiryTapped
                )
        ) {
            SafariView(url: .init(string: "https://www.google.com/?hl=ja")!)
        }
    }

    func version(viewStore: ViewStore<MyPage.State, MyPage.Action>) -> some View {
        Button(action: {
            viewStore.send(.versionTapped(appVersion))
        }) {
            HStack {
                rowTitle(symbolName: "iphone.homebutton", iconColor: .orange, title: "バージョン")
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
                } withDependencies: {
                    $0.authenticationClient.login = { _ in
                        AuthenticationResponse(token: "deadbeef")
                    }
                }
            )
        }
    }
}

