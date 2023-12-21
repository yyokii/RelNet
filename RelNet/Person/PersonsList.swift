//
//  PersonsList.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/19.
//

import ComposableArchitecture
import SwiftUI

/**
 特定のGroupに属するPersonのリスト表示機能
 */
struct PersonsList: Reducer {

    struct State: Equatable {
        @PresentationState var destination: Destination.State?
        var selectedGroup: Group
        let groups: IdentifiedArrayOf<Group>
        var persons: IdentifiedArrayOf<Person>

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
    }

    enum Action: Equatable {
        // User Action
        case cancelEditGroupButtonTapped
        case doneEditingGroupButtonTapped
        case deleteGroupButtonTapped
        case editGroupButtonTapped
        case personItemTapped(Person)

        // Other Action
        case destination(PresentationAction<Destination.Action>)
        case deleteGroupResult(TaskResult<String>)
        case editGroupResult(TaskResult<Group>)
    }

    struct Destination: Reducer {
        enum State: Equatable {
            case alert(AlertState<Action.Alert>)
            case editGroup(GroupForm.State)
            case personDetail(PersonDetail.State)
        }

        enum Action: Equatable {
            case alert(Alert)
            case editGroup(GroupForm.Action)
            case personDetail(PersonDetail.Action)

            enum Alert {
                case confirmDeletion
            }
        }

        var body: some ReducerOf<Self> {
            Scope(state: /State.editGroup, action: /Action.editGroup) {
                GroupForm()
            }
            Scope(state: /State.personDetail, action: /Action.personDetail) {
                PersonDetail()
            }
        }
    }

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.personClient) private var personClient

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .cancelEditGroupButtonTapped:
                state.destination = nil
                return .none

            case .doneEditingGroupButtonTapped:
                guard case let .some(.editGroup(editState)) = state.destination
                else { return .none }

                let group = editState.group
                return .run { send in
                    await send(
                        .editGroupResult(
                            await TaskResult {
                                try personClient.updateGroup(group)
                            }
                        )
                    )
                }

            case .deleteGroupButtonTapped:
                state.destination = .alert(.deleteGroup)
                return .none

            case .editGroupButtonTapped:
                state.destination = .editGroup(.init(group: state.selectedGroup))
                return .none

            case let .personItemTapped(person):
                state.destination = .personDetail(.init(person: person, groups: state.groups))
                return .none

            case let .destination(.presented(.alert(alertAction))):
                switch alertAction {
                case .confirmDeletion:
                    guard let id = state.selectedGroup.id else {
                        return .none
                    }

                    return .run { send in
                        await send(
                            .deleteGroupResult(
                                await TaskResult {
                                    try personClient.deleteGroup(id)
                                }
                            )
                        )
                    }
                }

            case let .destination(.presented(.personDetail(.delegate(.personDeleted(deletedPersonId))))):
                guard let index = state.persons.firstIndex(where: { $0.id == deletedPersonId }) else {
                    return .none
                }

                state.persons.remove(at: index)
                return .none

            case let .destination(.presented(.personDetail(.delegate(.personUpdated(updatedPerson))))):
                guard let index = state.persons.firstIndex(where: { $0.id == updatedPerson.id }) else {
                    return .none
                }

                if updatedPerson.groupIDs.contains(state.selectedGroup.id!) {
                    state.persons[index] = updatedPerson
                } else {
                    state.persons.remove(at: index)
                }

                return .none

            case .destination:
                return .none

            case .deleteGroupResult(.success(_)):
                print("📝 success delete group")
                return .run { _ in
                    await dismiss()
                }

            case .deleteGroupResult(.failure(_)):
                print("📝 failed delete group")
                return .none

            case let .editGroupResult(.success(group)):
                print("📝 success edit group")
                state.selectedGroup = group
                state.destination = nil
                return .none

            case .editGroupResult(.failure(_)):
                print("📝 failed edit group")
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }
}

struct PersonsListView: View {
    let store: StoreOf<PersonsList>

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView {
                SortedPersonsView(
                    sortedItems: viewStore.state.sortedPersons,
                    onTapPerson: { person in
                        viewStore.send(.personItemTapped(person))
                    }
                )
                .padding()
            }
            .navigationTitle("\(viewStore.state.selectedGroup.name)")
            .toolbar {
                headerMenu
            }
            .alert(
                store: store.scope(state: \.$destination, action: { .destination($0) }),
                state: /PersonsList.Destination.State.alert,
                action: PersonsList.Destination.Action.alert
            )
            .navigationDestination(
                store: store.scope(state: \.$destination, action: { .destination($0) }),
                state: /PersonsList.Destination.State.personDetail,
                action: PersonsList.Destination.Action.personDetail
            ) {
                PersonDetailView(store: $0)
            }
            .sheet(
                store: store.scope(state: \.$destination, action: { .destination($0) }),
                state: /PersonsList.Destination.State.editGroup,
                action: PersonsList.Destination.Action.editGroup
            ) { store in
                NavigationStack {
                    GroupFormView(store: store)
                        .navigationTitle(viewStore.selectedGroup.name)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    viewStore.send(.cancelEditGroupButtonTapped)
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("done-button-title") {
                                    viewStore.send(.doneEditingGroupButtonTapped)
                                }
                            }
                        }
                }
            }
        }
    }
}

private extension PersonsListView {
    var headerMenu: some View {
        Menu {
            HapticButton {
                store.send(.editGroupButtonTapped)
            } label: {
                HStack {
                    Text("edit-button-title")
                    Image(systemName: "pencil")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
            }

            HapticButton {
                store.send(.deleteGroupButtonTapped)
            } label: {
                Text("delete-button-title")
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 20))
                .foregroundColor(.primary)
        }
    }
}

extension AlertState where Action == PersonsList.Destination.Action.Alert {
    static let deleteGroup = Self {
        TextState("delete-alert-title")
    } actions: {
        ButtonState(role: .destructive, action: .confirmDeletion) {
            TextState("Yes")
        }
        ButtonState(role: .cancel) {
            TextState("Cancel")
        }
    } message: {
        TextState("グループを削除します。このグループ内の人物の情報は削除されません。")
    }
}

#if DEBUG

    #Preview {
        NavigationView {
            PersonsListView(
                store: Store(
                    initialState: PersonsList.State(
                        selectedGroup: .mock(id: "id-1"),
                        groups: .init(uniqueElements: [.mock(id: "id-1"), .mock(id: "id-2")]),
                        persons: .init(uniqueElements: [.mock(id: "id-1"), .mock(id: "id-2")])
                    )
                ) {
                    PersonsList()
                }
            )
        }
    }

#endif
