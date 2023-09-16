//
//  MainView.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/13.
//

import Foundation
import SwiftUI

import ComposableArchitecture

struct Main: Reducer {

    struct State: Equatable {
        @PresentationState var destination: Destination.State?

        var groups: IdentifiedArrayOf<Group> = []
        var persons: IdentifiedArrayOf<Person> = []

        init(
            destination: Destination.State? = nil
        ) {
            self.destination = destination
        }
    }

    enum Action: Equatable {
        // TODO: enum作成して分けてもいいかも
        // User Action
        case addGroupButtonTapped
        case addPersonButtonTapped
        case confirmAddGroupButtonTapped
        case confirmAddPersonButtonTapped
        case dismissAddGroupButtonTapped
        case dismissAddPersonButtonTapped
        case groupCardTapped(Group)
        case personCardTapped(Person)

        // Other Action
        case addGroupResult(TaskResult<Group>)
        case addPersonResult(TaskResult<Person>)
        case destination(PresentationAction<Destination.Action>)
        case listenGroups // TODO: task等のライフスタイルの命名にしたいが、複数待受けできるんだっけ
        case listenPersons
        case listenGroupsResponse(TaskResult<IdentifiedArrayOf<Group>>)
        case listenPersonsResponse(TaskResult<IdentifiedArrayOf<Person>>)
    }

    struct Destination: Reducer {
        enum State: Equatable {
            case addGroup(GroupForm.State)
            case addPerson(PersonForm.State)
            case groupDetail(GroupDetail.State)
            case personDetail(PersonDetail.State)
        }

        enum Action: Equatable {
            case addGroup(GroupForm.Action)
            case addPerson(PersonForm.Action)
            case groupDetail(GroupDetail.Action)
            case personDetail(PersonDetail.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: /State.addGroup, action: /Action.addGroup) {
                GroupForm()
            }
            Scope(state: /State.addPerson, action: /Action.addPerson) {
                PersonForm()
            }
            Scope(state: /State.groupDetail, action: /Action.groupDetail) {
                GroupDetail()
            }
            Scope(state: /State.personDetail, action: /Action.personDetail) {
                PersonDetail()
            }
        }
    }

    @Dependency(\.authenticationClient) private var authenticationClient
    @Dependency(\.personClient) private var personClient

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {

            case .addGroupButtonTapped:
                state.destination = .addGroup(GroupForm.State(group: Group()))
                return .none

            case .addPersonButtonTapped:
                state.destination = .addPerson(PersonForm.State(person: Person(), groups: state.groups))
                return .none

            case .confirmAddGroupButtonTapped:
                guard case let .some(.addGroup(formState)) = state.destination else {
                    return .none
                }

                let group = formState.group

                return .run { send in
                    try personClient.addGroup(group)
                    await send(.addGroupResult(.success(group)))
                } catch: { error, send in
                    await send(.addGroupResult(.failure(error)))
                }

            case .confirmAddPersonButtonTapped:
                guard case let .some(.addPerson(formState)) = state.destination else {
                    return .none
                }

                let person = formState.person

                return .run { send in
                    try personClient.addPerson(person)
                    await send(.addPersonResult(.success(person)))
                } catch: { error, send in
                    await send(.addPersonResult(.failure(error)))
                }

            case .dismissAddGroupButtonTapped:
                state.destination = nil
                return .none

            case .dismissAddPersonButtonTapped:
                state.destination = nil
                return .none

            case let .groupCardTapped(group):
                state.destination = .groupDetail(GroupDetail.State(group: group))
                return .none

            case let .personCardTapped(person):
                state.destination = .personDetail(PersonDetail.State(person: person, groups: state.groups))
                return .none

            case .addGroupResult(.success(_)):
                print("📝 success add Group")
                state.destination = nil
                return .none

            case .addGroupResult(.failure(_)):
                print("📝 failed add person")
                return .none

            case .addPersonResult(.success(_)):
                print("📝 success add person")
                state.destination = nil
                return .none

            case .addPersonResult(.failure(_)):
                print("📝 failed add person")
                return .none

            case .destination:
                return .none

            case .listenGroups:
                return .run { send in
                    for try await result in try await self.personClient.listenGroups() {
                        await send(.listenGroupsResponse(.success(result)))
                    }
                } catch: { error, send in
                    await send(.listenGroupsResponse(.failure(error)))
                }

            case .listenPersons:
                return .run { send in
                    for try await result in try await self.personClient.listenPersons() {
                        await send(.listenPersonsResponse(.success(result)))
                    }
                } catch: { error, send in
                    await send(.listenPersonsResponse(.failure(error)))
                }

            case let .listenGroupsResponse(.success(groups)):
                state.groups = groups
                return .none

            case let .listenGroupsResponse(.failure(error)):
                print(error.localizedDescription)
                return .none

            case let .listenPersonsResponse(.success(persons)):
                state.persons = persons
                return .none

            case let .listenPersonsResponse(.failure(error)):
                print(error.localizedDescription)
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }
}

struct MainView: View {
    let store: StoreOf<Main>

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView {
                groupList(viewStore)
                personsList(viewStore)
            }
            .navigationTitle("RelNet")
            .task {
                await viewStore.send(.listenGroups).finish()
            }
            .task {
                await viewStore.send(.listenPersons).finish()
            }
            .navigationDestination(
                store: store.scope(state: \.$destination, action: { .destination($0) }),
                state: /Main.Destination.State.groupDetail,
                action: Main.Destination.Action.groupDetail
            ) {
                GroupDetailView(store: $0)
            }
            .navigationDestination(
                store: store.scope(state: \.$destination, action: { .destination($0) }),
                state: /Main.Destination.State.personDetail,
                action: Main.Destination.Action.personDetail
            ) {
                PersonDetailView(store: $0)
            }
            .sheet(
                store: self.store.scope(state: \.$destination, action: { .destination($0) }),
                state: /Main.Destination.State.addGroup,
                action: Main.Destination.Action.addGroup
            ) { store in
                NavigationStack {
                    GroupFormView(store: store)
                        .navigationTitle("New Group")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Dismiss") {
                                    viewStore.send(.dismissAddGroupButtonTapped)
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Add") {
                                    viewStore.send(.confirmAddGroupButtonTapped)
                                }
                            }
                        }
                }
            }
            .sheet(
                store: self.store.scope(state: \.$destination, action: { .destination($0) }),
                state: /Main.Destination.State.addPerson,
                action: Main.Destination.Action.addPerson
            ) { store in
                NavigationStack {
                    PersonFormView(store: store)
                        .navigationTitle("New Person")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Dismiss") {
                                    viewStore.send(.dismissAddPersonButtonTapped)
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Add") {
                                    viewStore.send(.confirmAddPersonButtonTapped)
                                }
                            }
                        }
                }
            }
        }
    }
}

private extension MainView {
    func groupList(_ viewStore: ViewStore<Main.State, Main.Action>) -> some View {
        VStack {
            Text("Groups")
            Button {
                viewStore.send(.addGroupButtonTapped)
            } label: {
                Image(systemName: "plus")
            }
            ForEach(viewStore.state.groups) { group in
                Button {
                    viewStore.send(.groupCardTapped(group))
                } label: {
                    GroupCardView(group: group)
                }
            }
        }
    }

    func personsList(_ viewStore: ViewStore<Main.State, Main.Action>) -> some View {
        VStack {
            Text("Persons")
            Button {
                viewStore.send(.addPersonButtonTapped)
            } label: {
                Image(systemName: "plus")
            }
            ForEach(viewStore.state.persons) { person in
                Button {
                    viewStore.send(.personCardTapped(person))
                } label: {
                    PersonCardView(person: person)
                }
            }
        }
    }
}

struct PersonCardView: View {
    let person: Person

    var body: some View {
        VStack(alignment: .leading) {
            Text(self.person.name)
                .font(.headline)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cyan)
        }
    }
}

struct GroupCardView: View {
    let group: Group

    var body: some View {
        VStack(alignment: .leading) {
            Text(self.group.name)
                .font(.headline)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MainView(
                store: Store(initialState: Main.State()) {
                    Main()
                }
            )
        }
    }
}

