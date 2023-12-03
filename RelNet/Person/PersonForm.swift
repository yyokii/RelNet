//
//  PersonForm.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/27.
//

import ComposableArchitecture
import SwiftUI
import SwiftUINavigation

/**
 Person情報の入力ができる機能
 */
struct PersonForm: Reducer {

    struct State: Equatable, Sendable {
        @BindingState var focus: Field? = .name
        @BindingState var person: Person
        let groups: IdentifiedArrayOf<Group>

        init(person: Person, groups: IdentifiedArrayOf<Group>) {
            self.person = person
            self.groups = groups
        }

        enum Field: Hashable {
            case name
        }
    }

    enum Action: BindableAction, Equatable, Sendable {

        // User Action
        case binding(BindingAction<State>)
        case contactedTodayButtonTapped
        case groupButtonTapped(Group)

        // Other
        case nameEndEditing
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

            case .nameEndEditing:
                state.person.furigana = state.person.name.furigana
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
                        // TODO: 家族や食べ物、音楽などの person 情報を入力できるようにする
                        TextField("名前", text: viewStore.$person.name)
                            .focused(self.$focus, equals: .name)
                            .onChange(of: viewStore.state.focus) { focus in
                                if focus != .name {
                                    viewStore.send(.nameEndEditing)
                                }
                            }
                        TextField("フリガナ", text: viewStore.$person.furigana.toUnwrapped(defaultValue: ""))
                        TextField("ニックネーム", text: viewStore.$person.nickname.toUnwrapped(defaultValue: ""))
                        TextField("趣味", text: viewStore.$person.hobbies.toUnwrapped(defaultValue: ""))
                        TextField("好きなこと", text: viewStore.$person.likes.toUnwrapped(defaultValue: ""))
                        TextField("苦手なこと", text: viewStore.$person.dislikes.toUnwrapped(defaultValue: ""))
                        DatePicker("生年月日", selection: viewStore.$person.birthdate.toUnwrapped(defaultValue: defaultBirthDate), displayedComponents: [.date])
                    }
                } header: {
                    Text("Basic Info")
                }

                Section {
                    VStack {
                        TextField("親", text: viewStore.$person.parents.toUnwrapped(defaultValue: ""))
                        TextField("兄弟/姉妹", text: viewStore.$person.sibling.toUnwrapped(defaultValue: ""))
                        TextField("ペット", text: viewStore.$person.pets.toUnwrapped(defaultValue: ""))
                    }
                } header: {
                    Text("Family")
                }

                Section {
                    VStack {
                        TextField("好きな食べ物", text: viewStore.$person.likeFoods.toUnwrapped(defaultValue: ""))
                        TextField("好きなお菓子", text: viewStore.$person.likeSweets.toUnwrapped(defaultValue: ""))
                        TextField("アレルギー", text: viewStore.$person.allergies.toUnwrapped(defaultValue: ""))
                        TextField("苦手な食べ物", text: viewStore.$person.dislikeFoods.toUnwrapped(defaultValue: ""))
                    }
                } header: {
                    Text("Food")
                }

                Section {
                    VStack {
                        TextField("好きなジャンル", text: viewStore.$person.likeMusicCategories.toUnwrapped(defaultValue: ""))
                        TextField("好きなアーティスト", text: viewStore.$person.likeArtists.toUnwrapped(defaultValue: ""))
                        TextField("好きな曲", text: viewStore.$person.likeMusics.toUnwrapped(defaultValue: ""))
                        TextField("演奏できる楽器", text: viewStore.$person.playableInstruments.toUnwrapped(defaultValue: ""))
                    }
                } header: {
                    Text("Music")
                }

                Section {
                    VStack {
                        TextField("行った国", text: viewStore.$person.travelCountries.toUnwrapped(defaultValue: ""))
                        TextField("お気に入りの場所", text: viewStore.$person.favoriteLocations.toUnwrapped(defaultValue: ""))
                    }
                } header: {
                    Text("Travel")
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

                Section {
                    groupList
                } header: {
                    Text("Groups")
                }
                .listRowBackground(Color.clear)
            }
            .bind(viewStore.$focus, to: self.$focus)
        }
    }
}

private extension PersonFormView {
    var groupList: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            FlowLayout(alignment: .center, spacing: 8) {
                ForEach(viewStore.groups) { group in
                    Button {
                        viewStore.send(.groupButtonTapped(group))
                    } label: {
                        Text(group.name)
                            .groupItemText()
                    }
                    .buttonStyle(.plain)
                    .background {
                        let isSelectedGroup = viewStore.person.groupIDs.contains(group.id ?? "")
                        return RoundedRectangle(cornerRadius: GroupItemModifier.cornerRadius)
                            .fill(isSelectedGroup ? .blue.opacity(0.3) : .clear)
                    }
                }
            }
        }
    }
}

struct PersonForm_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PersonFormView(
                store: Store(
                    initialState: PersonForm.State(
                        person: .mock(),
                        groups: .init(uniqueElements: [.mock()])
                    )
                ) {
                    PersonForm()
                }
            )
        }
    }
}
