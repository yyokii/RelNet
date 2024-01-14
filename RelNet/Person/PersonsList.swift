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
@Reducer
struct PersonsList {
    struct State: Equatable {
        @PresentationState var destination: Destination.State?
        var selectedGroup: Group
        let groups: IdentifiedArrayOf<Group>
        var persons: IdentifiedArrayOf<Person>
    }

    enum Action: Equatable {
        // User Action
        case cancelEditGroupButtonTapped
        case deleteGroupButtonTapped
        case editGroupButtonTapped
        case personItemTapped(Person)

        // Other Action
        case destination(PresentationAction<Destination.Action>)
        case deleteGroupResult(TaskResult<String>)
    }

    @Reducer
    struct Destination {
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
    @Dependency(\.appClient) private var appClient

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .cancelEditGroupButtonTapped:
                state.destination = nil
                return .none

            case .deleteGroupButtonTapped:
                state.destination = .alert(.deleteGroup)
                return .none

            case .editGroupButtonTapped:
                state.destination = .editGroup(.init(group: state.selectedGroup, mode: .edit))
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
                                    try appClient.deleteGroup(id)
                                }
                            )
                        )
                    }
                }
            case let .destination(.presented(.editGroup(.delegate(.groupUpdated(updatedGroup))))):
                state.destination = nil
                state.selectedGroup = updatedGroup
                return .none

            case let .destination(.presented(.personDetail(.delegate(.personDeleted(deletedPersonId))))):
                state.destination = nil

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

            case .deleteGroupResult(.success(_)):
                print("📝 success delete group")
                return .run { _ in
                    await dismiss()
                }

            case .deleteGroupResult(.failure(_)):
                print("📝 failed delete group")
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

struct PersonsListView: View {
    let store: StoreOf<PersonsList>

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView {
                SortedPersonsView(
                    persons: viewStore.state.persons,
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
                store: store.scope(state: \.$destination.alert, action: \.destination.alert)
            )
            .navigationDestination(
                store: store.scope(state: \.$destination.personDetail, action: \.destination.personDetail)
            ) {
                PersonDetailView(store: $0)
            }
            .sheet(
                store: store.scope(state: \.$destination.editGroup, action: \.destination.editGroup)
            ) { store in
                NavigationStack {
                    GroupFormView(store: store)
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
            TextState("yes")
        }
        ButtonState(role: .cancel) {
            TextState("cancel")
        }
    } message: {
        TextState("delete-group-alert-message")
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
