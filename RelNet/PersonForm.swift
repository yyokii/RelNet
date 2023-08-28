//
//  PersonForm.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/27.
//

import SwiftUI

import ComposableArchitecture
import SwiftUINavigation

struct PersonForm: Reducer {

    struct State: Equatable, Sendable {
        @BindingState var focus: Field? = .firstName
        @BindingState var person: Person

        init(focus: Field? = .firstName, person: Person) {
            self.focus = focus
            self.person = person
        }

        enum Field: Hashable {
            case firstName
        }
    }

    enum Action: BindableAction, Equatable, Sendable {
        case binding(BindingAction<State>)
    }

    @Dependency(\.uuid) var uuid

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

struct PersonFormView: View {
    let store: StoreOf<PersonForm>
    @FocusState var focus: PersonForm.State.Field?

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Form {
                Section {
                    TextField("demo", text: viewStore.$person.firstName.toUnwrapped(defaultValue: ""))
                        .focused(self.$focus, equals: .firstName)
                } header: {
                    Text("Person")
                }
            }
            .bind(viewStore.$focus, to: self.$focus)
        }
    }
}

struct PersonForm_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PersonFormView(
                store: Store(initialState: PersonForm.State(person: .mock)) {
                    PersonForm()
                }
            )
        }
    }
}
