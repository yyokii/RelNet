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

        var sortedPersons: Dictionary<String, [Person]> {
            var dict: Dictionary<String, [Person]> = [:]
            for person in persons {
                let initial = person.nameInitial
                if dict[initial] != nil {
                    dict[initial]?.append(person)
                } else {
                    dict[initial] = [person]
                }
            }

            return dict
        }

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
        case personItemTapped(Person)
        case moreGroupsButtonTapped
        case morePersonsButtonTapped

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
            case groupsList(GroupsList.State)
            case personDetail(PersonDetail.State)
            case personsList(PersonsList.State)
        }

        enum Action: Equatable {
            case addGroup(GroupForm.Action)
            case addPerson(PersonForm.Action)
            case groupsList(GroupsList.Action)
            case personDetail(PersonDetail.Action)
            case personsList(PersonsList.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: /State.addGroup, action: /Action.addGroup) {
                GroupForm()
            }
            Scope(state: /State.addPerson, action: /Action.addPerson) {
                PersonForm()
            }
            Scope(state: /State.groupsList, action: /Action.groupsList) {
                GroupsList()
            }
            Scope(state: /State.personDetail, action: /Action.personDetail) {
                PersonDetail()
            }
            Scope(state: /State.personsList, action: /Action.personsList) {
                PersonsList()
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
                    await send (
                        .addGroupResult(
                            await TaskResult {
                                try personClient.addGroup(group)
                            }
                        )
                    )
                }

            case .confirmAddPersonButtonTapped:
                guard case let .some(.addPerson(formState)) = state.destination else {
                    return .none
                }

                let person = formState.person

                return .run { send in
                    await send (
                        .addPersonResult(
                            await TaskResult {
                                try personClient.addPerson(person)
                            }
                        )
                    )
                }

            case .dismissAddGroupButtonTapped:
                state.destination = nil
                return .none

            case .dismissAddPersonButtonTapped:
                state.destination = nil
                return .none

            case let .groupCardTapped(group):
                guard let groupId = group.id else {
                    return .none
                }

                let personsInGroup = state.persons.filter { person in
                    person.groupIDs.contains(groupId)
                }
                state.destination = .personsList(.init(selectedGroup: group, groups: state.groups, persons: personsInGroup))
                return .none

            case let .personItemTapped(person):
                state.destination = .personDetail(PersonDetail.State(person: person, groups: state.groups))
                return .none

            case .moreGroupsButtonTapped:
                state.destination = .groupsList(.init(groups: state.groups, persons: state.persons))
                return .none

            case .morePersonsButtonTapped:
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
                VStack(alignment: .leading, spacing: 32) {
                    listHeader(
                        title: "Groups",
                        moreAction: { viewStore.send(.moreGroupsButtonTapped) },
                        addAction: { viewStore.send(.addGroupButtonTapped) }
                    )
                    .padding(.top)
                    .padding(.horizontal)

                    // 横スクロールのViewにholizontalのpaddingをつけないようにするために個々のViewに.padding()を設定している。
                    groupList(viewStore)

                    personsList(viewStore)
                        .padding(.horizontal)
                }
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
                state: /Main.Destination.State.groupsList,
                action: Main.Destination.Action.groupsList
            ) {
                GroupsListView(store: $0)
                    .navigationTitle("Groups")
            }
            .navigationDestination(
                store: store.scope(state: \.$destination, action: { .destination($0) }),
                state: /Main.Destination.State.personDetail,
                action: Main.Destination.Action.personDetail
            ) {
                PersonDetailView(store: $0)
            }
            .navigationDestination(
                store: store.scope(state: \.$destination, action: { .destination($0) }),
                state: /Main.Destination.State.personsList,
                action: Main.Destination.Action.personsList
            ) {
                PersonsListView(store: $0)
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
        ScrollView(.horizontal) {
            LazyHStack(spacing: 12) {
                ForEach(viewStore.groups) { group in
                    Button {
                        viewStore.send(.groupCardTapped(group))
                    } label: {
                        GroupCard(group: group)
                    }
                    .padding(.leading)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    func personsList(_ viewStore: ViewStore<Main.State, Main.Action>) -> some View {
        VStack(alignment: .leading) {
            listHeader(
                title: "Persons",
                moreAction: nil,
                addAction: { viewStore.send(.addPersonButtonTapped) }
            )

            SortedPersonsView(
                sortedItems: viewStore.sortedPersons,
                onTapPerson: { person in
                    viewStore.send(.personItemTapped(person))
                }
            )
        }
    }

    func listHeader(title: String, moreAction: (() -> Void)?, addAction: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            if let moreAction {
                Button {
                    moreAction()
                } label: {
                    HStack {
                        Text(title)
                            .font(.title3)
                            .bold()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18))
                            .bold()
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text(title)
                    .font(.title3)
                    .bold()
            }

            Spacer()

            Button {
                addAction()
            } label: {
                Text("追加")
            }
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

