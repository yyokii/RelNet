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
            case lastName
        }
    }

    enum Action: BindableAction, Equatable, Sendable {
        case binding(BindingAction<State>)
        case contactedTodayButtonTapped
    }

    @Dependency(\.uuid) var uuid

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            case .contactedTodayButtonTapped:
                state.person.lastContacted = Date()
                return .none
            }
        }
    }
}

struct PersonFormView: View {
    let store: StoreOf<PersonForm>

    @FocusState var focus: PersonForm.State.Field?

    let defaultBirthDate: Date = Date()

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Form {
                Section {
                    VStack {
                        TextField("first name", text: viewStore.$person.firstName.toUnwrapped(defaultValue: ""))
                            .focused(self.$focus, equals: .firstName)
                        TextField("last name", text: viewStore.$person.lastName.toUnwrapped(defaultValue: ""))
                            .focused(self.$focus, equals: .lastName)
                        
                        TextField("nickname", text: viewStore.$person.nickname.toUnwrapped(defaultValue: ""))

                        // TODO: 年いる？あまり入れれない気がする、年と月日を分けるとか？
                        DatePicker("生年月日", selection: viewStore.$person.birthdate.toUnwrapped(defaultValue: defaultBirthDate), displayedComponents: [.date])
                    }
                } header: {
                    Text("Basic Info")
                }
                
                Section {
                    VStack {
                        Button {
                            viewStore.send(.contactedTodayButtonTapped)
                        } label: {
                            Text("いつ会った？")
                        }

                        TextEditor(text: viewStore.$person.notes.toUnwrapped(defaultValue: ""))
                    }
                } header: {
                    Text("Additional Info")
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
