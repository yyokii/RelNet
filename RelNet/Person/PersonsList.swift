//
//  PersonsList.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/19.
//

import SwiftUI

import ComposableArchitecture

struct PersonsList: Reducer {

    struct State: Equatable {
        @PresentationState var destination: Destination.State?
        let selectedGroup: Group
        let groups: IdentifiedArrayOf<Group>
        var persons: IdentifiedArrayOf<Person>
    }

    enum Action: Equatable {
        case destination(PresentationAction<Destination.Action>)
        case personItemTapped(Person)
    }

    struct Destination: Reducer {
        enum State: Equatable {
            case personDetail(PersonDetail.State)
        }

        enum Action: Equatable {
            case personDetail(PersonDetail.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: /State.personDetail, action: /Action.personDetail) {
                PersonDetail()
            }
        }
    }

    @Dependency(\.personClient) private var personClient

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .destination(.presented(.personDetail(.deletePersonResult(.success(deletedPersonId))))):
                guard let index = state.persons.firstIndex(where: { $0.id == deletedPersonId }) else {
                    return .none
                }

                state.persons.remove(at: index)
                return .none

            case let .destination(.presented(.personDetail(.editPersonResult(.success(updatedPerson))))):
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

            case let .personItemTapped(person):
                state.destination = .personDetail(.init(person: person, groups: state.groups))
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
                LazyVStack {
                    ForEach(viewStore.state.persons) { person in
                        Button {
                            viewStore.send(.personItemTapped(person))
                        } label: {
                            PersonCardView(person: person)
                        }
                    }
                }
            }
            .navigationTitle("\(viewStore.state.selectedGroup.name) persons")
            .navigationDestination(
                store: store.scope(state: \.$destination, action: { .destination($0) }),
                state: /PersonsList.Destination.State.personDetail,
                action: PersonsList.Destination.Action.personDetail
            ) {
                PersonDetailView(store: $0)
            }
        }
    }
}

struct PersonsList_Previews: PreviewProvider {
    static var previews: some View {
        PersonsListView(
            store: Store(initialState: PersonsList.State(
                selectedGroup: .mock,
                groups: .init(uniqueElements: [.mock, .mock]),
                persons: .init(uniqueElements: [.mock, .mock])
            )) {
                PersonsList()
            }
        )
    }
}


