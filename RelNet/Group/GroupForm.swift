//
//  GroupForm.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/29.
//

import SwiftUI

import ComposableArchitecture
import SwiftUINavigation

struct GroupForm: Reducer {

    struct State: Equatable, Sendable {
        @BindingState var focus: Field? = .name
        @BindingState var group: Group

        init(focus: Field? = .name, group: Group) {
            self.focus = focus
            self.group = group
        }

        enum Field: Hashable {
            case name
        }
    }

    enum Action: BindableAction, Equatable, Sendable {
        case binding(BindingAction<State>)

        case addGroupButtonTapped
        case addGroupResult(TaskResult<Group>)
        case dismissButtonTapped
    }

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.personClient) private var personClient
    @Dependency(\.authenticationClient) private var authenticationClient

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none

            case .addGroupButtonTapped:
                let addGroup = state.group
                return .run { send in
                    try personClient.addGroup(addGroup)
                    await send(.addGroupResult(.success(addGroup)))
                } catch: { error, send in
                    await send(.addGroupResult(.failure(error)))
                }

            case .dismissButtonTapped:
                return .run { _ in
                    await self.dismiss()
                }

            case .addGroupResult(.success(_)):
                print("📝 success add Group")
                return .run { _ in
                    await self.dismiss()
                }

            case .addGroupResult(.failure(_)):
                print("📝 failed add person")
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
                        TextField("name", text: viewStore.$group.name)
                            .focused(self.$focus, equals: .name)
                    }
                } header: {
                    Text("Info")
                }
            }
            .bind(viewStore.$focus, to: self.$focus)
            .navigationTitle("New Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") {
                        viewStore.send(.dismissButtonTapped)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewStore.send(.addGroupButtonTapped)
                    }
                }
            }
        }
    }
}

struct GroupForm_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            GroupFormView(
                store: Store(initialState: GroupForm.State(group: .mock)) {
                    GroupForm()
                }
            )
        }
    }
}

