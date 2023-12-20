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
                    groupList
                } header: {
                    Text("group-section-title")
                }
                .listRowBackground(Color.clear)

                Section {
                    VStack {
                        ValidatableTextField(
                            placeholder: "名前",
                            validatable: PersonInputType.name(viewStore.$person.name)
                        )
                        .focused(self.$focus, equals: .name)
                        .onChange(of: viewStore.state.focus) { focus in
                            if focus != .name {
                                viewStore.send(.nameEndEditing)
                            }
                        }
                        ValidatableTextField(
                            placeholder: "フリガナ",
                            validatable: PersonInputType.other(viewStore.$person.furigana.toUnwrapped(defaultValue: ""))
                        )
                        ValidatableTextField(
                            placeholder: "ニックネーム",
                            validatable: PersonInputType.other(viewStore.$person.nickname.toUnwrapped(defaultValue: ""))
                        )
                        ValidatableTextField(
                            placeholder: "趣味",
                            validatable: PersonInputType.other(viewStore.$person.hobbies.toUnwrapped(defaultValue: ""))
                        )
                        ValidatableTextField(
                            placeholder: "好きなこと",
                            validatable: PersonInputType.other(viewStore.$person.likes.toUnwrapped(defaultValue: ""))
                        )
                        ValidatableTextField(
                            placeholder: "苦手なこと",
                            validatable: PersonInputType.other(viewStore.$person.dislikes.toUnwrapped(defaultValue: ""))
                        )
                        DatePicker("生年月日", selection: viewStore.$person.birthdate.toUnwrapped(defaultValue: defaultBirthDate), displayedComponents: [.date])
                    }
                } header: {
                    Text("basic-info-section-title")
                }

                Section {
                    VStack {
                        ValidatableTextField(
                            placeholder: "親",
                            validatable: PersonInputType.other(viewStore.$person.parents.toUnwrapped(defaultValue: ""))
                        )
                        ValidatableTextField(
                            placeholder: "兄弟/姉妹",
                            validatable: PersonInputType.other(viewStore.$person.sibling.toUnwrapped(defaultValue: ""))
                        )
                        ValidatableTextField(
                            placeholder: "ペット",
                            validatable: PersonInputType.other(viewStore.$person.pets.toUnwrapped(defaultValue: ""))
                        )
                    }
                } header: {
                    Text("family-section-title")
                }

                Section {
                    VStack {
                        ValidatableTextField(
                            placeholder: "好きな食べ物",
                            validatable: PersonInputType.other(viewStore.$person.likeFoods.toUnwrapped(defaultValue: ""))
                        )
                        ValidatableTextField(
                            placeholder: "好きなお菓子",
                            validatable: PersonInputType.other(viewStore.$person.likeSweets.toUnwrapped(defaultValue: ""))
                        )
                        ValidatableTextField(
                            placeholder: "アレルギー",
                            validatable: PersonInputType.other(viewStore.$person.allergies.toUnwrapped(defaultValue: ""))
                        )
                        ValidatableTextField(
                            placeholder: "苦手な食べ物",
                            validatable: PersonInputType.other(viewStore.$person.dislikeFoods.toUnwrapped(defaultValue: ""))
                        )
                    }
                } header: {
                    Text("food-section-title")
                }

                Section {
                    VStack {
                        ValidatableTextField(
                            placeholder: "好きなジャンル",
                            validatable: PersonInputType.other(viewStore.$person.likeMusicCategories.toUnwrapped(defaultValue: ""))
                        )
                        ValidatableTextField(
                            placeholder: "好きなアーティスト",
                            validatable: PersonInputType.other(viewStore.$person.likeArtists.toUnwrapped(defaultValue: ""))
                        )
                        ValidatableTextField(
                            placeholder: "好きな曲",
                            validatable: PersonInputType.other(viewStore.$person.likeMusics.toUnwrapped(defaultValue: ""))
                        )
                        ValidatableTextField(
                            placeholder: "演奏できる楽器",
                            validatable: PersonInputType.other(viewStore.$person.playableInstruments.toUnwrapped(defaultValue: ""))
                        )
                    }
                } header: {
                    Text("music-section-title")
                }

                Section {
                    VStack {
                        ValidatableTextField(
                            placeholder: "行った国",
                            validatable: PersonInputType.other(viewStore.$person.travelCountries.toUnwrapped(defaultValue: ""))
                        )
                        ValidatableTextField(
                            placeholder: "お気に入りの場所",
                            validatable: PersonInputType.other(viewStore.$person.favoriteLocations.toUnwrapped(defaultValue: ""))
                        )
                    }
                } header: {
                    Text("travel-section-title")
                }
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
