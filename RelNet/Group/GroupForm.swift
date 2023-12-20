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
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
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
                            validatable: PersonInputType.name(viewStore.$group.name)
                        )
                    .focused(self.$focus, equals: .name)
                    }
                } header: {
                    Text("group-section-title")
                }
            }
            .bind(viewStore.$focus, to: self.$focus)
        }
    }
}

struct GroupForm_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            GroupFormView(
                store: Store(initialState: GroupForm.State(group: .mock())) {
                    GroupForm()
                }
            )
        }
    }
}
