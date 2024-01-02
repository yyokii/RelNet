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
        let mode: Mode
        let validator: PersonInputValidator = .init()

        var enableDoneButton: Bool {
            validator.isValidPerson(person)
        }

        init(person: Person, groups: IdentifiedArrayOf<Group>, mode: Mode) {
            self.person = person
            self.groups = groups
            self.mode = mode
        }

        enum Field: Hashable {
            case name
        }

        enum Mode: Hashable {
            case create
            case edit
        }
    }

    enum Action: BindableAction, Equatable, Sendable {

        // User Action
        case doneButtonTapped
        case contactedTodayButtonTapped
        case groupButtonTapped(Group)
        case nameEndEditing

        case delegate(DelegateAction)

        case binding(BindingAction<State>)
        case addPersonResult(TaskResult<Person>)
        case editPersonResult(TaskResult<Person>)

        enum DelegateAction: Equatable {
            case personUpdated(Person)
        }
    }

    @Dependency(\.personClient) private var personClient

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .contactedTodayButtonTapped:
                state.person.lastContacted = Date()
                return .none

            case .doneButtonTapped:
                let person = state.person

                switch state.mode {
                case .create:
                    return .run { send in
                        await send(
                            .addPersonResult(
                                await TaskResult {
                                    try personClient.addPerson(person)
                                }
                            )
                        )
                    }
                case .edit:
                    return .run { send in
                        await send(
                            .editPersonResult(
                                await TaskResult {
                                    try self.personClient.updatePerson(person)
                                }
                            )
                        )
                    }
                }

            case let .groupButtonTapped(group):
                guard let id = group.id else {
                    return .none
                }
                state.person.updateGroupID(id)
                return .none

            case .nameEndEditing:
                guard let furigana = state.person.furigana,
                    furigana.isEmpty
                else {
                    return .none
                }
                state.person.furigana = state.person.name.furigana
                return .none

            case let .addPersonResult(.success(person)):
                return .send(.delegate(.personUpdated(person)))

            case .addPersonResult(.failure(_)):
                print("📝 failed add person")
                return .none

            case let .editPersonResult(.success(person)):
                print("📝 success edit person")
                return .send(.delegate(.personUpdated(person)))

            case .editPersonResult(.failure(_)):
                print("📝 failed edit person")
                return .none

            case .delegate, .binding:
                return .none
            }
        }
    }
}

/**
 Person情報の入力ができる画面

 どの画面から本画面を表示するかでtoolbarに表示するボタンが変更するので、
 利用するViewにおいてtoolbarの設定とその処理（作成、更新）を担うようにしている。
 → の方針だったが、toolbarのボタンの状態を本画面で操作したかったので、modeを持って処理を振り分けるようにした
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
                            text: viewStore.$person.name,
                            validationResult: viewStore.validator.validate(
                                value: viewStore.person.name,
                                type: .name
                            )
                        )
                        .focused(self.$focus, equals: .name)
                        .onChange(of: viewStore.state.focus) { focus in
                            if focus != .name {
                                viewStore.send(.nameEndEditing)
                            }
                        }
                        ValidatableTextField(
                            placeholder: "フリガナ",
                            text: viewStore.$person.furigana.toUnwrapped(defaultValue: ""),
                            validationResult: viewStore.validator.validate(
                                value: viewStore.person.furigana,
                                type: .other
                            )
                        )
                        ValidatableTextField(
                            placeholder: "ニックネーム",
                            text: viewStore.$person.nickname.toUnwrapped(defaultValue: ""),
                            validationResult: viewStore.validator.validate(
                                value: viewStore.person.nickname,
                                type: .other
                            )
                        )
                        DatePicker("生年月日", selection: viewStore.$person.birthdate.toUnwrapped(defaultValue: defaultBirthDate), displayedComponents: [.date])
                        ValidatableTextField(
                            placeholder: "住所",
                            text: viewStore.$person.address.toUnwrapped(defaultValue: ""),
                            validationResult: viewStore.validator.validate(
                                value: viewStore.person.address,
                                type: .other
                            )
                        )
                        ValidatableTextField(
                            placeholder: "趣味",
                            text: viewStore.$person.hobbies.toUnwrapped(defaultValue: ""),
                            validationResult: viewStore.validator.validate(
                                value: viewStore.person.hobbies,
                                type: .other
                            )
                        )
                        ValidatableTextField(
                            placeholder: "好きなこと",
                            text: viewStore.$person.likes.toUnwrapped(defaultValue: ""),
                            validationResult: viewStore.validator.validate(
                                value: viewStore.person.likes,
                                type: .other
                            )
                        )
                        ValidatableTextField(
                            placeholder: "苦手なこと",
                            text: viewStore.$person.dislikes.toUnwrapped(defaultValue: ""),
                            validationResult: viewStore.validator.validate(
                                value: viewStore.person.dislikes,
                                type: .other
                            )
                        )
                    }
                } header: {
                    Text("basic-info-section-title")
                }

                Section {
                    VStack {
                        ValidatableTextField(
                            placeholder: "親",
                            text: viewStore.$person.parents.toUnwrapped(defaultValue: ""),
                            validationResult: viewStore.validator.validate(
                                value: viewStore.person.parents,
                                type: .other
                            )
                        )
                        ValidatableTextField(
                            placeholder: "兄弟/姉妹",
                            text: viewStore.$person.sibling.toUnwrapped(defaultValue: ""),
                            validationResult: viewStore.validator.validate(
                                value: viewStore.person.sibling,
                                type: .other
                            )
                        )
                        ValidatableTextField(
                            placeholder: "ペット",
                            text: viewStore.$person.pets.toUnwrapped(defaultValue: ""),
                            validationResult: viewStore.validator.validate(
                                value: viewStore.person.pets,
                                type: .other
                            )
                        )
                    }
                } header: {
                    Text("family-section-title")
                }

                Section {
                    VStack {
                        ValidatableTextField(
                            placeholder: "好きな食べ物",
                            text: viewStore.$person.likeFoods.toUnwrapped(defaultValue: ""),
                            validationResult: viewStore.validator.validate(
                                value: viewStore.person.likeFoods,
                                type: .other
                            )
                        )
                        ValidatableTextField(
                            placeholder: "好きなお菓子",
                            text: viewStore.$person.likeSweets.toUnwrapped(defaultValue: ""),
                            validationResult: viewStore.validator.validate(
                                value: viewStore.person.likeSweets,
                                type: .other
                            )
                        )
                        ValidatableTextField(
                            placeholder: "アレルギー",
                            text: viewStore.$person.allergies.toUnwrapped(defaultValue: ""),
                            validationResult: viewStore.validator.validate(
                                value: viewStore.person.allergies,
                                type: .other
                            )
                        )
                        ValidatableTextField(
                            placeholder: "苦手な食べ物",
                            text: viewStore.$person.dislikeFoods.toUnwrapped(defaultValue: ""),
                            validationResult: viewStore.validator.validate(
                                value: viewStore.person.dislikeFoods,
                                type: .other
                            )
                        )
                    }
                } header: {
                    Text("food-section-title")
                }

                Section {
                    VStack {
                        ValidatableTextField(
                            placeholder: "好きなジャンル",
                            text: viewStore.$person.likeMusicCategories.toUnwrapped(defaultValue: ""),
                            validationResult: viewStore.validator.validate(
                                value: viewStore.person.likeMusicCategories,
                                type: .other
                            )
                        )
                        ValidatableTextField(
                            placeholder: "好きなアーティスト",
                            text: viewStore.$person.likeArtists.toUnwrapped(defaultValue: ""),
                            validationResult: viewStore.validator.validate(
                                value: viewStore.person.likeArtists,
                                type: .other
                            )
                        )
                        ValidatableTextField(
                            placeholder: "好きな曲",
                            text: viewStore.$person.likeMusics.toUnwrapped(defaultValue: ""),
                            validationResult: viewStore.validator.validate(
                                value: viewStore.person.likeMusics,
                                type: .other
                            )
                        )
                        ValidatableTextField(
                            placeholder: "演奏できる楽器",
                            text: viewStore.$person.playableInstruments.toUnwrapped(defaultValue: ""),
                            validationResult: viewStore.validator.validate(
                                value: viewStore.person.playableInstruments,
                                type: .other
                            )
                        )
                    }
                } header: {
                    Text("music-section-title")
                }

                Section {
                    VStack {
                        ValidatableTextField(
                            placeholder: "行った国",
                            text: viewStore.$person.travelCountries.toUnwrapped(defaultValue: ""),
                            validationResult: viewStore.validator.validate(
                                value: viewStore.person.travelCountries,
                                type: .other
                            )
                        )
                        ValidatableTextField(
                            placeholder: "お気に入りの場所",
                            text: viewStore.$person.favoriteLocations.toUnwrapped(defaultValue: ""),
                            validationResult: viewStore.validator.validate(
                                value: viewStore.person.favoriteLocations,
                                type: .other
                            )
                        )
                    }
                } header: {
                    Text("travel-section-title")
                }
            }
            .bind(viewStore.$focus, to: self.$focus)
            .navigationTitle(viewStore.person.name)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("done-button-title") {
                        viewStore.send(.doneButtonTapped)
                    }
                    .disabled(!viewStore.enableDoneButton)
                }
            }
        }
    }
}

private extension PersonFormView {
    var groupList: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            FlowLayout(alignment: .leading, spacing: 8) {
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

#if DEBUG

    struct PersonForm_Previews: PreviewProvider {
        static var previews: some View {
            NavigationStack {
                PersonFormView(
                    store: Store(
                        initialState: PersonForm.State(
                            person: .mock(),
                            groups: .init(uniqueElements: [.mock()]),
                            mode: .create
                        )
                    ) {
                        PersonForm()
                    }
                )
            }
        }
    }

#endif
