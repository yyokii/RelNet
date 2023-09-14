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
        case binding(BindingAction<State>)

        case contactedTodayButtonTapped
        case groupButtonTapped(Group)
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
