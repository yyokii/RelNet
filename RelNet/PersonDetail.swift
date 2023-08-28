//
//  PersonDetail.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/27.
//

import SwiftUI

import ComposableArchitecture

struct PersonDetail: Reducer {

    struct State: Equatable {
        @PresentationState var destination: Destination.State?
        var person: Person
    }
    enum Action: Equatable, Sendable {
        case cancelEditButtonTapped
        case delegate(Delegate)
        case deleteButtonTapped
        case destination(PresentationAction<Destination.Action>)
        case doneEditingButtonTapped
        case editButtonTapped

        enum Delegate: Equatable {
            case deletePerson
            case personUpdated(Person)
        }
    }

    @Dependency(\.dismiss) var dismiss

    struct Destination: Reducer {
        enum State: Equatable {
            case alert(AlertState<Action.Alert>)
            case edit(PersonForm.State)
        }
        enum Action: Equatable, Sendable {
            case alert(Alert)
            case edit(PersonForm.Action)

            enum Alert {
                case confirmDeletion
            }
        }
        var body: some ReducerOf<Self> {
            Scope(state: /State.edit, action: /Action.edit) {
                PersonForm()
            }
        }
    }

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .cancelEditButtonTapped:
                state.destination = nil
                return .none

            case .delegate:
                return .none

            case .deleteButtonTapped:
                state.destination = .alert(.deletePerson)
                return .none

            case let .destination(.presented(.alert(alertAction))):
                switch alertAction {
                case .confirmDeletion:
                    return .run { send in
                        await send(.delegate(.deletePerson), animation: .default)
                        await self.dismiss()
                    }
                }

            case .destination:
                return .none

            case .doneEditingButtonTapped:
                guard case let .some(.edit(editState)) = state.destination
                else { return .none }
                state.person = editState.person
                state.destination = nil
                return .none

            case .editButtonTapped:
                state.destination = .edit(PersonForm.State(person: state.person))
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
        .onChange(of: \.person) { oldValue, newValue in
            Reduce { state, action in
                    .send(.delegate(.personUpdated(newValue)))
            }
        }
    }
}

struct PersonDetailView: View {
    let store: StoreOf<PersonDetail>

    struct ViewState: Equatable {
        let person: Person

        init(state: PersonDetail.State) {
            self.person = state.person
        }
    }

    var body: some View {
        WithViewStore(self.store, observe: ViewState.init) { viewStore in
            List {
                Section {
                    Button("Delete") {
                        viewStore.send(.deleteButtonTapped)
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(viewStore.person.firstName ?? "")
            .toolbar {
                Button("Edit") {
                    viewStore.send(.editButtonTapped)
                }
            }
            .alert(
                store: self.store.scope(state: \.$destination, action: { .destination($0) }),
                state: /PersonDetail.Destination.State.alert,
                action: PersonDetail.Destination.Action.alert
            )
            .sheet(
                store: self.store.scope(state: \.$destination, action: { .destination($0) }),
                state: /PersonDetail.Destination.State.edit,
                action: PersonDetail.Destination.Action.edit
            ) { store in
                NavigationStack {
                    PersonFormView(store: store)
                        .navigationTitle(viewStore.person.firstName ?? "")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    viewStore.send(.cancelEditButtonTapped)
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    viewStore.send(.doneEditingButtonTapped)
                                }
                            }
                        }
                }
            }
        }
    }
}

extension AlertState where Action == PersonDetail.Destination.Action.Alert {
    static let deletePerson = Self {
        TextState("Delete?")
    } actions: {
        ButtonState(role: .destructive, action: .confirmDeletion) {
            TextState("Yes")
        }
        ButtonState(role: .cancel) {
            TextState("Nevermind")
        }
    } message: {
        TextState("Are you sure you want to delete this meeting?")
    }
}

struct PersonDetail_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PersonDetailView(
                store: Store(initialState: PersonDetail.State(person: .mock)) {
                    PersonDetail()
                }
            )
        }
    }
}

