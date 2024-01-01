//
//  GroupForm.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/29.
//

import ComposableArchitecture
import SwiftUI
import SwiftUINavigation

struct GroupForm: Reducer {

    struct State: Equatable, Sendable {
        @BindingState var focus: Field? = .name
        @BindingState var group: Group

        let mode: Mode
        let validator: GroupInputValidator = .init()

        var enableDoneButton: Bool {
            validator.isValidGroup(group)
        }

        init(
            focus: Field? = .name,
            group: Group,
            mode: Mode
        ) {
            self.focus = focus
            self.group = group
            self.mode = mode
        }

        enum Field: Hashable {
            case name
        }

        enum Mode: Hashable {
            case create
            case edit
        }
    }

    enum Action: BindableAction, Equatable, Sendable {
        case binding(BindingAction<State>)
        case doneButtonTapped

        case delegate(DelegateAction)

        case addGroupResult(TaskResult<Group>)
        case editGroupResult(TaskResult<Group>)

        enum DelegateAction: Equatable {
            case groupUpdated(Group)
        }
    }

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.personClient) private var personClient

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .doneButtonTapped:
                let group = state.group

                switch state.mode {
                case .create:
                    return .run { send in
                        await send(
                            .addGroupResult(
                                .init {
                                    try personClient.addGroup(group)
                                }
                            )
                        )
                    }
                case .edit:
                    return .run { send in
                        await send(
                            .editGroupResult(
                                await TaskResult {
                                    try personClient.updateGroup(group)
                                }
                            )
                        )
                    }
                }
            case let .addGroupResult(.success(group)):
                return .send(.delegate(.groupUpdated(group)))

            case .addGroupResult(.failure(_)):
                print("📝 failed add person")
                return .none

            case let .editGroupResult(.success(group)):
                return .send(.delegate(.groupUpdated(group)))

            case .editGroupResult(.failure(_)):
                print("📝 failed edit group")
                return .none
            case .binding, .delegate:
                return .none
            }
        }
    }
}

struct GroupFormView: View {
    let store: StoreOf<GroupForm>

    @FocusState var focus: GroupForm.State.Field?

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Form {
                Section {
                    VStack {
                        ValidatableTextField(
                            placeholder: "group-name-title",
                            text: viewStore.$group.name,
                            validationResult: viewStore.validator.validate(
                                value: viewStore.group.name,
                                type: .name
                            )
                        )
                        .focused(self.$focus, equals: .name)
                    }
                } header: {
                    Text("group-section-title")
                }
            }
            .bind(viewStore.$focus, to: self.$focus)
            .navigationTitle(viewStore.group.name)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("done-button-title") {
                        viewStore.send(.doneButtonTapped)
                    }
                    .disabled(!viewStore.enableDoneButton)
                }
            }
        }
    }
}

#if DEBUG

    struct GroupForm_Previews: PreviewProvider {
        static var previews: some View {
            NavigationStack {
                GroupFormView(
                    store: Store(initialState: GroupForm.State(group: .mock(), mode: .create)) {
                        GroupForm()
                    }
                )
            }
        }
    }

#endif
