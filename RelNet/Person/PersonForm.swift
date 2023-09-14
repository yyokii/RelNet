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
        let group: IdentifiedArrayOf<Group>

        init(person: Person, group: IdentifiedArrayOf<Group>) {
            self.person = person
            self.group = group
        }

        enum Field: Hashable {
            case firstName
            case lastName
        }
    }

    enum Action: BindableAction, Equatable, Sendable {
        case binding(BindingAction<State>)

        case addPersonButtonTapped
        case addPersonResult(TaskResult<Person>)
        case contactedTodayButtonTapped
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

            case .addPersonButtonTapped:
                let addPerson = state.person
                return .run { send in
                    try personClient.addPerson(addPerson)
                    await send(.addPersonResult(.success(addPerson)))
                } catch: { error, send in
                    await send(.addPersonResult(.failure(error)))
                }

            case .contactedTodayButtonTapped:
                state.person.lastContacted = Date()
                return .none

            case .dismissButtonTapped:
                return .run { _ in
                    await self.dismiss()
                }

            case .addPersonResult(.success(_)):
                print("📝 success add person")
                return .run { _ in
                    await self.dismiss()
                }

            case .addPersonResult(.failure(_)):
                print("📝 failed add person")
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
                        TextField("first name", text: viewStore.$person.firstName)
                            .focused(self.$focus, equals: .firstName)
                        TextField("last name", text: viewStore.$person.lastName)
                            .focused(self.$focus, equals: .lastName)
                        
                        TextField("nickname", text: viewStore.$person.nickname)

                        // TODO: 年いる？あまり入れれない気がする、年と月日を分けるとか？
                        DatePicker("生年月日", selection: viewStore.$person.birthdate.toUnwrapped(defaultValue: defaultBirthDate), displayedComponents: [.date])
                    }
                } header: {
                    Text("Basic Info")
                }

//                Section {
//                    ForEach(groups) { group in
//                        HStack {
//                            Label(group.name, systemImage: "paintpalette")
//                                .padding(4)
//
//                            Button {
//                                viewStore.send(.contactedTodayButtonTapped)
//                            } label: {
//                                Text("設定")
//                            }
//                        }
//                    }
//                } header: {
//                    Text("Groups")
//                }
                
                Section {
                    VStack {
                        Button {
                            viewStore.send(.contactedTodayButtonTapped)
                        } label: {
                            Text("いつ会った？")
                        }

                        TextEditor(text: viewStore.$person.notes)
                    }
                } header: {
                    Text("Additional Info")
                }
            }
            .bind(viewStore.$focus, to: self.$focus)
            .navigationTitle("New Person")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") {
                        viewStore.send(.dismissButtonTapped)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewStore.send(.addPersonButtonTapped)
                    }
                }
            }
        }
    }
}

//struct GroupPicker: View {
//    @Binding var selection: Group
//    let groups: IdentifiedArrayOf<Group>
//
//    var body: some View {
//        Picker("Group", selection: self.$selection) {
//            ForEach(groups) { group in
//                ZStack {
//                    Label(group.name, systemImage: "paintpalette")
//                        .padding(4)
//                }
//                .tag(group)
//            }
//        }
//    }
//}

struct PersonForm_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PersonFormView(
                store: Store(
                    initialState: PersonForm.State(
                        person: .mock,
                        group: .init(uniqueElements: [.mock])
                    )
                ) {
                    PersonForm()
                }
            )
        }
    }
}
