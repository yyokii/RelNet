//
//  GroupList.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/19.
//

import SwiftUI

import ComposableArchitecture

struct GroupsList: Reducer {

    struct State: Equatable {
        @PresentationState var destination: Destination.State?
        var groups: IdentifiedArrayOf<Group>
        let persons: IdentifiedArrayOf<Person>
    }

    enum Action: Equatable {
        case destination(PresentationAction<Destination.Action>)
        case groupItemTapped(Group)
    }

    struct Destination: Reducer {
        enum State: Equatable {
            case personsList(PersonsList.State)
        }

        enum Action: Equatable {
            case personsList(PersonsList.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: /State.personsList, action: /Action.personsList) {
                PersonsList()
            }
        }
    }

    @Dependency(\.personClient) private var personClient

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .destination(.presented(.personsList(.deleteGroupResult(.success(deletedGroupId))))):
                guard let index = state.groups.firstIndex(where: { $0.id == deletedGroupId }) else {
                    return .none
                }

                state.groups.remove(at: index)
                return .none

            case let .destination(.presented(.personsList(.editGroupResult(.success(updatedGroup))))):
                guard let index = state.groups.firstIndex(where: { $0.id == updatedGroup.id }) else {
                    return .none
                }

                state.groups[index] = updatedGroup
                return .none

            case .destination:
                return .none

            case let .groupItemTapped(group):
                guard let groupId = group.id else {
                    return .none
                }

                let personsInGroup = state.persons.filter { person in
                    person.groupIDs.contains(groupId)
                }
                state.destination = .personsList(.init(selectedGroup: group, groups: state.groups, persons: personsInGroup))
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }
}

struct GroupsListView: View {
    let store: StoreOf<GroupsList>

    var body: some View {
        WithViewStore(self.store, observe: \.groups) { viewStore in
            ScrollView {
                LazyVStack {
                    ForEach(viewStore.state) { group in
                        Button {
                            viewStore.send(.groupItemTapped(group))
                        } label: {
                            GroupCard(group: group)
                        }
                    }
                }
            }
            .navigationDestination(
                store: store.scope(state: \.$destination, action: { .destination($0) }),
                state: /GroupsList.Destination.State.personsList,
                action: GroupsList.Destination.Action.personsList
            ) {
                PersonsListView(store: $0)
            }
        }
    }
}

struct GroupList_Previews: PreviewProvider {
    static var previews: some View {
        GroupsListView(
            store: Store(initialState: GroupsList.State(
                groups: .init(uniqueElements: [.mock, .mock]),
                persons: .init(uniqueElements: [.mock, .mock])
            )) {
                GroupsList()
            }
        )
    }
}

