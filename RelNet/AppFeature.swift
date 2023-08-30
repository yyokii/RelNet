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
        var personsList = PersonsList.State()
        var groupsList = GroupsList.State()
    }

    enum Action: Equatable {
        case path(StackAction<Path.State, Path.Action>)
        case personsList(PersonsList.Action)
        case groupsList(GroupsList.Action)
    }

    @Dependency(\.uuid) var uuid

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
            case let .path(.element(id, .detail(.delegate(delegateAction)))):
                guard case let .some(.detail(detailState)) = state.path[id: id]
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
            case detail(PersonDetail.State)
        }

        enum Action: Equatable {
            case detail(PersonDetail.Action)
        }

        var body: some Reducer<State, Action> {
            Scope(state: /State.detail, action: /Action.detail) {
                PersonDetail()
            }
        }
    }
}

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        TabView {
            personsListTab
            groupsListTab
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
            switch $0 {
            case .detail:
                CaseLet(
                    /AppFeature.Path.State.detail,
                     action: AppFeature.Path.Action.detail,
                     then: PersonDetailView.init(store:)
                )
            }
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
            switch $0 {
            case .detail:
                CaseLet(
                    /AppFeature.Path.State.detail,
                     action: AppFeature.Path.Action.detail,
                     then: PersonDetailView.init(store:)
                )
            }
        }
        .tabItem {
            Label("groups", systemImage: "rectangle.3.group.fill")
        }
    }
}
