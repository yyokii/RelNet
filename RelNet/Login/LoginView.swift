//
//  LoginView.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/04.
//

import SwiftUI

import ComposableArchitecture
import Dispatch

struct Login: Reducer, Sendable {
    struct State: Equatable {
        @PresentationState var alert: AlertState<AlertAction>?
        @BindingState var email = ""
        var isFormValid = false
        var isLoginRequestInFlight = false
        @BindingState var password = ""

        init() {}
    }

    enum Action: Equatable, Sendable {
        case alert(PresentationAction<AlertAction>)
        case loginResponse(TaskResult<AuthenticationResponse>)
        case view(View)

        enum View: BindableAction, Equatable, Sendable {
            case binding(BindingAction<State>)
            case loginButtonTapped
        }
    }

    enum AlertAction: Equatable, Sendable {}

    @Dependency(\.authenticationClient) var authenticationClient

    init() {}

    var body: some Reducer<State, Action> {
        BindingReducer(action: /Action.view)
        Reduce { state, action in
            switch action {
            case .alert:
                return .none

            case let .loginResponse(.success(response)):
                state.isLoginRequestInFlight = false
                return .none

            case let .loginResponse(.failure(error)):
                state.alert = AlertState { TextState(error.localizedDescription) }
                state.isLoginRequestInFlight = false
                return .none

            case .view(.binding):
                state.isFormValid = !state.email.isEmpty && !state.password.isEmpty
                return .none

            case .view(.loginButtonTapped):
                state.isLoginRequestInFlight = true
                return .run { [email = state.email, password = state.password] send in
                    await send(
                        .loginResponse(
                            await TaskResult {
                                try await self.authenticationClient.login(
                                    .init(email: email, password: password)
                                )
                            }
                        )
                    )
                }
            }
        }
        .ifLet(\.$alert, action: /Action.alert)
    }
}

struct LoginView: View {
    let store: StoreOf<Login>

    struct ViewState: Equatable {
        @BindingViewState var email: String
        var isActivityIndicatorVisible: Bool
        var isFormDisabled: Bool
        var isLoginButtonDisabled: Bool
        @BindingViewState var password: String
    }

    init(store: StoreOf<Login>) {
        self.store = store
    }

    var body: some View {
        WithViewStore(self.store, observe: \.view, send: { .view($0) }) { viewStore in
            Form {
                Text(
          """
          To login use any email and password.
          """
                )

                Section {
                    TextField("blob@pointfree.co", text: viewStore.$email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)

                    SecureField("••••••••", text: viewStore.$password)
                }

                Button {
                    // NB: SwiftUI will print errors to the console about "AttributeGraph: cycle detected" if
                    //     you disable a text field while it is focused. This hack will force all fields to
                    //     unfocus before we send the action to the view store.
                    // CF: https://stackoverflow.com/a/69653555
                    _ = UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
                    )
                    viewStore.send(.loginButtonTapped)
                } label: {
                    HStack {
                        Text("Log in")
                        if viewStore.isActivityIndicatorVisible {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(viewStore.isLoginButtonDisabled)
            }
            .disabled(viewStore.isFormDisabled)
            .alert(store: self.store.scope(state: \.$alert, action: Login.Action.alert))
        }
        .navigationTitle("Login")
    }
}

extension BindingViewStore<Login.State> {
    var view: LoginView.ViewState {
        LoginView.ViewState(
            email: self.$email,
            isActivityIndicatorVisible: self.isLoginRequestInFlight,
            isFormDisabled: self.isLoginRequestInFlight,
            isLoginButtonDisabled: !self.isFormValid,
            password: self.$password
        )
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LoginView(
                store: Store(initialState: Login.State()) {
                    Login()
                } withDependencies: {
                    $0.authenticationClient.login = { _ in
                        AuthenticationResponse(token: "deadbeef")
                    }
                }
            )
        }
    }
}
