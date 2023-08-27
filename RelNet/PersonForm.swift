//
//  PersonForm.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/27.
//

import ComposableArchitecture
import SwiftUI
import SwiftUINavigation

struct PersonForm: Reducer {

    struct State: Equatable, Sendable {
        @BindingState var focus: Field? = .title
        @BindingState var person: Person

        init(focus: Field? = .title, person: Person) {
            self.focus = focus
            self.person = person
        }

        enum Field: Hashable {
            case title
        }
    }

    enum Action: BindableAction, Equatable, Sendable {
        case addButtonTapped
        case binding(BindingAction<State>)
    }

    @Dependency(\.uuid) var uuid

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .addButtonTapped:
                let person = Person()
                print("add person")
                return .none

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
                    TextField("Title", text: viewStore.$person.firstName.toUnwrapped(defaultValue: ""))
                        .focused(self.$focus, equals: .title)
                } header: {
                    Text("Standup Info")
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
