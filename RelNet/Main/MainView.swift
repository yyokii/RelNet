//
//  MainView.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/13.
//

import ComposableArchitecture
import Foundation
import OrderedCollections
import SwiftUI

@Reducer
struct Main {
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

    enum Action: TCAFeatureAction, Equatable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        case destination(PresentationAction<Destination.Action>)

        enum ViewAction: Equatable {
            case addGroupButtonTapped
            case addPersonButtonTapped
            case gearButtonTapped
            case groupCardTapped(Group)
            case listenGroups
            case listenPersons
            case personItemTapped(Person)
        }

        enum InternalAction: Equatable {
            case listenGroupsResponse(TaskResult<IdentifiedArrayOf<Group>>)
            case listenPersonsResponse(TaskResult<IdentifiedArrayOf<Person>>)
        }

        enum DelegateAction: Equatable {}
    }

    @Reducer
    struct Destination {
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
            Scope(state: \.groupForm, action: \.groupForm) {
                GroupForm()
            }
            Scope(state: \.myPage, action: \.myPage) {
                MyPage()
            }
            Scope(state: \.personForm, action: \.personForm) {
                PersonForm()
            }
            Scope(state: \.personDetail, action: \.personDetail) {
                PersonDetail()
            }
            Scope(state: \.personsList, action: \.personsList) {
                PersonsList()
            }
        }
    }

    @Dependency(\.authenticationClient) private var authenticationClient
    @Dependency(\.appClient) private var appClient

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .view(viewAction):
                switch viewAction {
                case .addGroupButtonTapped:
                    state.destination = .groupForm(GroupForm.State(group: Group(), mode: .create))
                    return .none
                case .addPersonButtonTapped:
                    state.destination = .personForm(PersonForm.State(person: Person(), groups: state.groups, mode: .create))
                    return .none
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
                        for try await result in try await self.appClient.listenGroups() {
                            await send(.internal(.listenGroupsResponse(.success(result))))
                        }
                    } catch: { error, send in
                        await send(.internal(.listenGroupsResponse(.failure(error))))
                    }
                case .listenPersons:
                    return .run { send in
                        for try await result in try await self.appClient.listenPersons() {
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

            case .destination(.presented(.groupForm(.delegate(.groupUpdated(_))))):
                state.destination = nil
                return .none

            case .destination(.presented(.personForm(.delegate(.personUpdated(_))))):
                state.destination = nil
                return .none

            case .destination(.presented(.personDetail(.delegate(.personDeleted(_))))):
                state.destination = nil
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            Destination()
        }
    }
}

struct MainView: View {
    private let store: StoreOf<Main>
    @ObservedObject private var viewStore: ViewStoreOf<Main>

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
            store: store.scope(state: \.$destination.personDetail, action: \.destination.personDetail)
        ) {
            PersonDetailView(store: $0)
        }
        .navigationDestination(
            store: store.scope(state: \.$destination.personsList, action: \.destination.personsList)
        ) {
            PersonsListView(store: $0)
        }
        .sheet(
            store: self.store.scope(state: \.$destination.groupForm, action: \.destination.groupForm)
        ) { store in
            NavigationStack {
                GroupFormView(store: store)
            }
        }
        .sheet(
            store: self.store.scope(state: \.$destination.personForm, action: \.destination.personForm)
        ) { store in
            NavigationView {
                PersonFormView(store: store)
            }
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
            store: self.store.scope(state: \.$destination.myPage, action: \.destination.myPage)
        ) { store in
            NavigationView {
                MyPageView(store: store)
            }
        }
    }

    var groupList: some View {
        VStack(alignment: .leading, spacing: 24) {
            listHeader(
                title: String(localized: "group-section-title"),
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
                        .buttonStyle(.plain)
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
                persons: viewStore.persons,
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
                    Text("add-button-title")
                }
            }
            .foregroundStyle(Color.appAccent)
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
                    $0.appClient.listenGroups = {
                        AsyncThrowingStream { continuation in
                            let persons: [Group] = []
                            continuation.yield(IdentifiedArray(uniqueElements: persons))
                            continuation.finish()
                        }
                    }
                    $0.appClient.listenPersons = {
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
