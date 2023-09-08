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
        var path = StackState<Path.State>()

        var isSignIn: Bool = false
        var personsList = PersonsList.State()
        var groupsList = GroupsList.State()
    }

    enum Action: Equatable {
        case signInWithGoogleButtonTapped
        case updateSignInState(Bool)
        case onAppear
        case path(StackAction<Path.State, Path.Action>)
        case personsList(PersonsList.Action)
        case groupsList(GroupsList.Action)
    }

    @Dependency(\.uuid) private var uuid
    @Dependency(\.authenticationClient) private var authenticationClient

    private enum CancelID {
        case saveDebounce
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.personsList, action: /Action.personsList) {
            PersonsList()
        }
        Scope(state: \.groupsList, action: /Action.groupsList) {
            GroupsList()
        }
        Reduce<State, Action> { state, action in
            switch action {
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
            case .onAppear:
                let user = authenticationClient.currentUser()
                state.isSignIn = user != nil
                return .none
            case let .path(.element(id, .groupDetail(.delegate(delegateAction)))):
                guard case let .some(.groupDetail(detailState)) = state.path[id: id]
                else { return .none }
                
                switch delegateAction {
                case .deleteGroup:
                    state.groupsList.groups.remove(id: detailState.group.id)
                    return .none
                    
                case let .groupUpdated(group):
                    state.groupsList.groups[id: group.id] = group
                    return .none
                }
                
            case let .path(.element(id, .personDetail(.delegate(delegateAction)))):
                guard case let .some(.personDetail(detailState)) = state.path[id: id]
                else { return .none }
                
                switch delegateAction {
                case .deletePerson:
                    state.personsList.persons.remove(id: detailState.person.id)
                    return .none

                case let .personUpdated(person):
                    state.personsList.persons[id: person.id] = person
                    return .none
                }

            case .path:
                return .none

            case .personsList:
                return .none

            case .groupsList:
                return .none
            }
        }
        .forEach(\.path, action: /Action.path) {
            Path()
        }
    }

    struct Path: Reducer {
        enum State: Equatable {
            case groupDetail(GroupDetail.State)
            case personDetail(PersonDetail.State)
        }
        
        enum Action: Equatable {
            case groupDetail(GroupDetail.Action)
            case personDetail(PersonDetail.Action)
        }
        
        var body: some Reducer<State, Action> {
            Scope(state: /State.groupDetail, action: /Action.groupDetail) {
                GroupDetail()
            }
            Scope(state: /State.personDetail, action: /Action.personDetail) {
                PersonDetail()
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
                    personsListTab
                    groupsListTab
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
    var personsListTab: some View {
        NavigationStackStore(self.store.scope(state: \.path, action: { .path($0) })) {
            PersonsListView(
                store: self.store.scope(state: \.personsList, action: { .personsList($0) })
            )
        } destination: {
            destinationView(state: $0)
        }
        .tabItem {
            Label("persons", systemImage: "person.crop.circle.fill")
        }
    }

    var groupsListTab: some View {
        NavigationStackStore(self.store.scope(state: \.path, action: { .path($0) })) {
            GroupsListView(
                store: self.store.scope(state: \.groupsList, action: { .groupsList($0) })
            )
        } destination: {
            destinationView(state: $0)
        }
        .tabItem {
            Label("groups", systemImage: "rectangle.3.group.fill")
        }
    }

    @ViewBuilder
    func destinationView(state: AppFeature.Path.State) -> some View {
        switch state {
        case .groupDetail:
            CaseLet(
                /AppFeature.Path.State.groupDetail,
                 action: AppFeature.Path.Action.groupDetail,
                 then: GroupDetailView.init(store:)
            )
        case .personDetail:
            CaseLet(
                /AppFeature.Path.State.personDetail,
                 action: AppFeature.Path.Action.personDetail,
                 then: PersonDetailView.init(store:)
            )
        }
    }
}
