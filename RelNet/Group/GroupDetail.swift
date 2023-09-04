//
//  GroupDetail.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/30.
//

import SwiftUI

import ComposableArchitecture

struct GroupDetail: Reducer {

    struct State: Equatable {
        @PresentationState var destination: Destination.State?
        var group: Group
    }

    enum Action: Equatable, Sendable {
        case cancelEditButtonTapped
        case delegate(Delegate)
        case deleteButtonTapped
        case destination(PresentationAction<Destination.Action>)
        case doneEditingButtonTapped
        case editButtonTapped

        enum Delegate: Equatable {
            case deleteGroup
            case groupUpdated(Group)
        }
    }

    @Dependency(\.dismiss) var dismiss

    struct Destination: Reducer {
        enum State: Equatable {
            case alert(AlertState<Action.Alert>)
            case edit(GroupForm.State)
        }
        enum Action: Equatable, Sendable {
            case alert(Alert)
            case edit(GroupForm.Action)

            enum Alert {
                case confirmDeletion
            }
        }
        var body: some ReducerOf<Self> {
            Scope(state: /State.edit, action: /Action.edit) {
                GroupForm()
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
                state.destination = .alert(.deleteGroup)
                return .none

            case let .destination(.presented(.alert(alertAction))):
                switch alertAction {
                case .confirmDeletion:
                    return .run { send in
                        await send(.delegate(.deleteGroup), animation: .default)
                        await self.dismiss()
                    }
                }

            case .destination:
                return .none

            case .doneEditingButtonTapped:
                guard case let .some(.edit(editState)) = state.destination
                else { return .none }
                state.group = editState.group
                state.destination = nil
                return .none

            case .editButtonTapped:
                state.destination = .edit(GroupForm.State(group: state.group))
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
        .onChange(of: \.group) { oldValue, newValue in
            Reduce { state, action in
                    .send(.delegate(.groupUpdated(newValue)))
            }
        }
    }
}

struct GroupDetailView: View {
    let store: StoreOf<GroupDetail>

    struct ViewState: Equatable {
        let group: Group

        init(state: GroupDetail.State) {
            self.group = state.group
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
            .navigationTitle(viewStore.group.name)
            .toolbar {
                Button("Edit") {
                    viewStore.send(.editButtonTapped)
                }
            }
            .alert(
                store: self.store.scope(state: \.$destination, action: { .destination($0) }),
                state: /GroupDetail.Destination.State.alert,
                action: GroupDetail.Destination.Action.alert
            )
            .sheet(
                store: self.store.scope(state: \.$destination, action: { .destination($0) }),
                state: /GroupDetail.Destination.State.edit,
                action: GroupDetail.Destination.Action.edit
            ) { store in
                NavigationStack {
                    GroupFormView(store: store)
                        .navigationTitle(viewStore.group.name)
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

extension AlertState where Action == GroupDetail.Destination.Action.Alert {
    static let deleteGroup = Self {
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

struct GroupDetail_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            GroupDetailView(
                store: Store(initialState: GroupDetail.State(group: .mock)) {
                    GroupDetail()
                }
            )
        }
    }
}
