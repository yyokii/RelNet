//
//  PersonForm.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/27.
//

import SwiftUI

import ComposableArchitecture
import SwiftUINavigation

/**
 Person情報の入力ができる機能
 */
struct PersonForm: Reducer {

    struct State: Equatable, Sendable {
        @BindingState var focus: Field? = .lastName
        @BindingState var person: Person
        let groups: IdentifiedArrayOf<Group>

        init(person: Person, groups: IdentifiedArrayOf<Group>) {
            self.person = person
            self.groups = groups
        }

        enum Field: Hashable {
            case firstName
            case lastName
        }
    }

    enum Action: BindableAction, Equatable, Sendable {

        // User Action
        case binding(BindingAction<State>)
        case contactedTodayButtonTapped
        case groupButtonTapped(Group)

        // Other
        case firstNameEndEditing
        case lastNameEndEditing
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none

            case .contactedTodayButtonTapped:
                state.person.lastContacted = Date()
                return .none

            case let .groupButtonTapped(group):
                guard let id = group.id else {
                    return .none
                }
                state.person.updateGroupID(id)
                return .none

            case .firstNameEndEditing:
                state.person.firstNameFurigana = state.person.firstName.furigana
                return .none

            case .lastNameEndEditing:
                state.person.lastNameFurigana = state.person.lastName.furigana
                return .none
            }
        }
    }
}

/**
 Person情報の入力ができる画面

 どの画面から本画面を表示するかでtoolbarに表示するボタンが変更するので、利用するViewにおいて
 toolbarの設定とその処理を担うようにしている。
 */
struct PersonFormView: View {
    let store: StoreOf<PersonForm>

    @FocusState var focus: PersonForm.State.Field?

    let defaultBirthDate: Date = Date()

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Form {
                Section {
                    VStack {
                        TextField("姓", text: viewStore.$person.lastName)
                            .focused(self.$focus, equals: .lastName)
                            .onChange(of: viewStore.state.focus) { focus in
                                if focus != .lastName {
                                    viewStore.send(.lastNameEndEditing)
                                }
                            }

                        TextField("姓（フリガナ）", text: viewStore.$person.lastNameFurigana.toUnwrapped(defaultValue: ""))

                        TextField("名", text: viewStore.$person.firstName)
                            .focused(self.$focus, equals: .firstName)

                        TextField("名（フリガナ）", text: viewStore.$person.firstNameFurigana.toUnwrapped(defaultValue: ""))
                            .onChange(of: viewStore.state.focus) { focus in
                                if focus != .firstName {
                                    viewStore.send(.firstNameEndEditing)
                                }
                            }
                        
                        TextField("nickname", text: viewStore.$person.nickname)

                        TextField("hobbies", text: viewStore.$person.hobbies)

                        TextField("likes", text: viewStore.$person.likes)

                        TextField("dislikes", text: viewStore.$person.dislikes)

                        // TODO: 年いる？あまり入れれない気がする、年と月日を分けるとか？
                        DatePicker("生年月日", selection: viewStore.$person.birthdate.toUnwrapped(defaultValue: defaultBirthDate), displayedComponents: [.date])
                    }
                } header: {
                    Text("Basic Info")
                }

                Section {
                    VStack(alignment: .leading) {
                        ForEach(viewStore.groups) { group in
                            HStack {
                                Label(group.name, systemImage: "paintpalette")

                                Spacer()

                                Button {
                                    viewStore.send(.groupButtonTapped(group))
                                } label: {
                                    if viewStore.person.groupIDs.contains(group.id ?? "") {
                                        Text("解除")
                                    } else {
                                        Text("設定")
                                    }
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                    }
                } header: {
                    Text("Groups")
                }
                
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
        }
    }
}

struct PersonForm_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PersonFormView(
                store: Store(
                    initialState: PersonForm.State(
                        person: .mock,
                        groups: .init(uniqueElements: [.mock])
                    )
                ) {
                    PersonForm()
                }
            )
        }
    }
}
