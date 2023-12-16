//
//  MainView.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/13.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct Main: Reducer {

    struct State: Equatable {
        @PresentationState var destination: Destination.State?

        var groups: IdentifiedArrayOf<Group> = []
        var persons: IdentifiedArrayOf<Person> = []

        var sortedPersons: [String: [Person]] {
            var dict: [String: [Person]] = [:]
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

    enum Action: TCAFeatureAction, Equatable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        case destination(PresentationAction<Destination.Action>)

        enum ViewAction: Equatable {
            case addGroupButtonTapped
            case addPersonButtonTapped
            case confirmAddGroupButtonTapped
            case confirmAddPersonButtonTapped
            case gearButtonTapped
            case groupCardTapped(Group)
            case listenGroups
            case listenPersons
            case personItemTapped(Person)
        }

        enum InternalAction: Equatable {
            case addGroupResult(TaskResult<Group>)
            case addPersonResult(TaskResult<Person>)
            case listenGroupsResponse(TaskResult<IdentifiedArrayOf<Group>>)
            case listenPersonsResponse(TaskResult<IdentifiedArrayOf<Person>>)
        }

        enum DelegateAction: Equatable {}
    }

    struct Destination: Reducer {
        // TODO: state名とcase名が一致してない
        enum State: Equatable {
            case groupForm(GroupForm.State)
            case myPage(MyPage.State)
            case personForm(PersonForm.State)
            case personDetail(PersonDetail.State)
            case personsList(PersonsList.State)
        }

        enum Action: Equatable {
            case groupForm(GroupForm.Action)
            case myPage(MyPage.Action)
            case personForm(PersonForm.Action)
            case personDetail(PersonDetail.Action)
            case personsList(PersonsList.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: /State.groupForm, action: /Action.groupForm) {
                GroupForm()
            }
            Scope(state: /State.myPage, action: /Action.myPage) {
                MyPage()
            }
            Scope(state: /State.personForm, action: /Action.personForm) {
                PersonForm()
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
            case let .view(viewAction):
                switch viewAction {
                case .addGroupButtonTapped:
                    state.destination = .groupForm(GroupForm.State(group: Group()))
                    return .none
                case .addPersonButtonTapped:
                    state.destination = .personForm(PersonForm.State(person: Person(), groups: state.groups))
                    return .none
                case .confirmAddGroupButtonTapped:
                    guard case let .some(.groupForm(formState)) = state.destination else {
                        return .none
                    }
                    let group = formState.group

                    return .run { send in
                        await send(
                            .internal(
                                .addGroupResult(
                                    .init {
                                        try personClient.addGroup(group)
                                    }
                                )
                            )
                        )
                    }
                case .confirmAddPersonButtonTapped:
                    guard case let .some(.personForm(formState)) = state.destination else {
                        return .none
                    }
                    let person = formState.person

                    return .run { send in
                        await send(
                            .internal(
                                .addPersonResult(
                                    await TaskResult {
                                        try personClient.addPerson(person)
                                    }
                                )
                            )
                        )
                    }
                case .gearButtonTapped:
                    state.destination = .myPage(.init())
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
                case .listenGroups:
                    return .run { send in
                        for try await result in try await self.personClient.listenGroups() {
                            await send(.internal(.listenGroupsResponse(.success(result))))
                        }
                    } catch: { error, send in
                        await send(.internal(.listenGroupsResponse(.failure(error))))
                    }
                case .listenPersons:
                    return .run { send in
                        for try await result in try await self.personClient.listenPersons() {
                            await send(.internal(.listenPersonsResponse(.success(result))))
                        }
                    } catch: { error, send in
                        await send(.internal(.listenPersonsResponse(.failure(error))))
                    }
                case let .personItemTapped(person):
                    state.destination = .personDetail(PersonDetail.State(person: person, groups: state.groups))
                    return .none
                }

            case let .internal(internalAction):
                switch internalAction {

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

            case .destination:
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
    @ObservedObject var viewStore: ViewStoreOf<Main>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                groupList
                    .padding(.top)
                personsList
            }
            .padding(.horizontal)
        }
        .navigationTitle("knot")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                gearButton
            }
        }
        .task {
            await viewStore.send(.view(.listenGroups)).finish()
        }
        .task {
            await viewStore.send(.view(.listenPersons)).finish()
        }
        .navigationDestination(
            store: store.scope(state: \.$destination, action: Main.Action.destination),
            state: /Main.Destination.State.personDetail,
            action: Main.Destination.Action.personDetail
        ) {
            PersonDetailView(store: $0)
        }
        .navigationDestination(
            store: store.scope(state: \.$destination, action: Main.Action.destination),
            state: /Main.Destination.State.personsList,
            action: Main.Destination.Action.personsList
        ) {
            PersonsListView(store: $0)
        }
        .sheet(
            store: self.store.scope(state: \.$destination, action: Main.Action.destination),
            state: /Main.Destination.State.groupForm,
            action: Main.Destination.Action.groupForm
        ) { store in
            groupForm(store: store)
        }
        .sheet(
            store: self.store.scope(state: \.$destination, action: Main.Action.destination),
            state: /Main.Destination.State.personForm,
            action: Main.Destination.Action.personForm
        ) { store in
            personForm(store: store)
        }
    }

    init(store: StoreOf<Main>) {
        self.store = store
        self.viewStore = ViewStore(self.store, observe: { $0 })
    }
}

private extension MainView {
    var gearButton: some View {
        Button {
            viewStore.send(.view(.gearButtonTapped))
        } label: {
            Image(systemName: "gearshape")
                .foregroundColor(.primary)
        }
        .sheet(
            store: self.store.scope(state: \.$destination, action: Main.Action.destination),
            state: /Main.Destination.State.myPage,
            action: Main.Destination.Action.myPage
        ) { store in
            NavigationView {
                MyPageView(store: store)
            }
        }
    }

    var groupList: some View {
        VStack(alignment: .leading, spacing: 24) {
            listHeader(
                title: "グループ",
                addAction: { viewStore.send(.view(.addGroupButtonTapped)) }
            )
            if viewStore.groups.isEmpty {
                Text("empty-groups-message")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.gray)
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
            } else {
                FlowLayout(alignment: .leading, spacing: 8) {
                    ForEach(viewStore.groups) { group in
                        Button {
                            viewStore.send(.view(.groupCardTapped(group)))
                        } label: {
                            Text(group.name)
                                .groupItemText()
                        }
                    }
                }
            }
        }
    }

    var personsList: some View {
        VStack(alignment: .leading, spacing: 24) {
            listHeader(
                title: String(localized: "person-list-title"),
                addAction: { viewStore.send(.view(.addPersonButtonTapped)) }
            )

            SortedPersonsView(
                sortedItems: viewStore.sortedPersons,
                onTapPerson: { person in
                    viewStore.send(.view(.personItemTapped(person)))
                }
            )
        }
    }

    func listHeader(
        title: String,
        addAction: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.title3)
                .bold()

            Spacer()

            Button {
                addAction()
            } label: {
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("追加")
                }
            }
        }
    }

    func groupForm(store: StoreOf<GroupForm>) -> some View {
        NavigationView {
            GroupFormView(store: store)
                .navigationTitle("group-form-title")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("add-button-title") {
                            viewStore.send(.view(.confirmAddGroupButtonTapped))
                        }
                    }
                }
        }
    }

    func personForm(store: StoreOf<PersonForm>) -> some View {
        NavigationView {
            PersonFormView(store: store)
                .navigationTitle("person-form-title")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("add-button-title") {
                            viewStore.send(.view(.confirmAddPersonButtonTapped))
                        }
                    }
                }
        }
    }
}

#if DEBUG

    #Preview("light") {
        NavigationView {
            MainView(
                store: Store(initialState: Main.State()) {
                    Main()
                }
            )
        }
        .environment(\.colorScheme, .light)
    }

    #Preview("dark") {
        NavigationView {
            MainView(
                store: Store(initialState: Main.State()) {
                    Main()
                }
            )
        }
        .environment(\.colorScheme, .dark)
    }

    #Preview("空") {
        NavigationView {
            MainView(
                store: Store(initialState: Main.State()) {
                    Main()
                } withDependencies: {
                    $0.personClient.listenGroups = {
                        AsyncThrowingStream { continuation in
                            let persons: [Group] = []
                            continuation.yield(IdentifiedArray(uniqueElements: persons))
                            continuation.finish()
                        }
                    }
                    $0.personClient.listenPersons = {
                        AsyncThrowingStream { continuation in
                            let persons: [Person] = []
                            continuation.yield(IdentifiedArray(uniqueElements: persons))
                            continuation.finish()
                        }
                    }
                }
            )
        }
    }

#endif
