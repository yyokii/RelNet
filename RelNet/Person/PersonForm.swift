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
@Reducer
struct PersonForm {
    struct State: Equatable, Sendable {
        @BindingState var focus: Field? = .name
        @BindingState var person: Person
        @BindingState var selectedContentType: ContentTypeSegmentedPicker.ContentType = .list

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
        case deleteBirthdateButtonTapped
        case doneButtonTapped
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

    @Dependency(\.appClient) private var appClient

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .deleteBirthdateButtonTapped:
                state.person.birthdate = nil
                return .none

            case .doneButtonTapped:
                let person = state.person

                switch state.mode {
                case .create:
                    return .run { send in
                        await send(
                            .addPersonResult(
                                await TaskResult {
                                    try appClient.addPerson(person)
                                }
                            )
                        )
                    }
                case .edit:
                    return .run { send in
                        await send(
                            .editPersonResult(
                                await TaskResult {
                                    try self.appClient.updatePerson(person)
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
    private let store: StoreOf<PersonForm>
    @ObservedObject private var viewStore: ViewStoreOf<PersonForm>

    @FocusState var focus: PersonForm.State.Field?

    let defaultBirthDate: Date = Date()

    var body: some View {
        Form {
            if !viewStore.groups.isEmpty {
                Section {
                    groupList
                } header: {
                    Text("group-section-title")
                }
                .listRowBackground(Color.clear)
            }

            ContentTypeSegmentedPicker(selectedContentType: viewStore.$selectedContentType)
            //                .listRowBackground(Color.clear)

            inputContent
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

    init(store: StoreOf<PersonForm>) {
        self.store = store
        self.viewStore = ViewStore(self.store, observe: { $0 })
    }
}

private extension PersonFormView {
    @ViewBuilder
    var inputContent: some View {
        switch viewStore.selectedContentType {
        case .list:
            Section {
                VStack {
                    ValidatableTextField(
                        placeholder: String(localized: "name"),
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
                        placeholder: String(localized: "furigana"),
                        text: viewStore.$person.furigana.toUnwrapped(defaultValue: ""),
                        validationResult: viewStore.validator.validate(
                            value: viewStore.person.furigana,
                            type: .other
                        )
                    )
                    ValidatableTextField(
                        placeholder: String(localized: "nick-name"),
                        text: viewStore.$person.nickname.toUnwrapped(defaultValue: ""),
                        validationResult: viewStore.validator.validate(
                            value: viewStore.person.nickname,
                            type: .other
                        )
                    )
                    birthDateRow
                    ValidatableTextField(
                        placeholder: String(localized: "address"),
                        text: viewStore.$person.address.toUnwrapped(defaultValue: ""),
                        validationResult: viewStore.validator.validate(
                            value: viewStore.person.address,
                            type: .other
                        )
                    )
                    ValidatableTextField(
                        placeholder: String(localized: "hobby"),
                        text: viewStore.$person.hobbies.toUnwrapped(defaultValue: ""),
                        validationResult: viewStore.validator.validate(
                            value: viewStore.person.hobbies,
                            type: .other
                        )
                    )
                    ValidatableTextField(
                        placeholder: String(localized: "like"),
                        text: viewStore.$person.likes.toUnwrapped(defaultValue: ""),
                        validationResult: viewStore.validator.validate(
                            value: viewStore.person.likes,
                            type: .other
                        )
                    )
                    ValidatableTextField(
                        placeholder: String(localized: "dislike"),
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
                        placeholder: String(localized: "parent"),
                        text: viewStore.$person.parents.toUnwrapped(defaultValue: ""),
                        validationResult: viewStore.validator.validate(
                            value: viewStore.person.parents,
                            type: .other
                        )
                    )
                    ValidatableTextField(
                        placeholder: String(localized: "siblings"),
                        text: viewStore.$person.sibling.toUnwrapped(defaultValue: ""),
                        validationResult: viewStore.validator.validate(
                            value: viewStore.person.sibling,
                            type: .other
                        )
                    )
                    ValidatableTextField(
                        placeholder: String(localized: "child"),
                        text: viewStore.$person.children.toUnwrapped(defaultValue: ""),
                        validationResult: viewStore.validator.validate(
                            value: viewStore.person.children,
                            type: .other
                        )
                    )
                    ValidatableTextField(
                        placeholder: String(localized: "pet"),
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
                        placeholder: String(localized: "favorite-food"),
                        text: viewStore.$person.likeFoods.toUnwrapped(defaultValue: ""),
                        validationResult: viewStore.validator.validate(
                            value: viewStore.person.likeFoods,
                            type: .other
                        )
                    )
                    ValidatableTextField(
                        placeholder: String(localized: "favorite-snacks"),
                        text: viewStore.$person.likeSweets.toUnwrapped(defaultValue: ""),
                        validationResult: viewStore.validator.validate(
                            value: viewStore.person.likeSweets,
                            type: .other
                        )
                    )
                    ValidatableTextField(
                        placeholder: String(localized: "allergy"),
                        text: viewStore.$person.allergies.toUnwrapped(defaultValue: ""),
                        validationResult: viewStore.validator.validate(
                            value: viewStore.person.allergies,
                            type: .other
                        )
                    )
                    ValidatableTextField(
                        placeholder: String(localized: "dislike"),
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
                        placeholder: String(localized: "favorite-genre"),
                        text: viewStore.$person.likeMusicCategories.toUnwrapped(defaultValue: ""),
                        validationResult: viewStore.validator.validate(
                            value: viewStore.person.likeMusicCategories,
                            type: .other
                        )
                    )
                    ValidatableTextField(
                        placeholder: String(localized: "favorite-artist"),
                        text: viewStore.$person.likeArtists.toUnwrapped(defaultValue: ""),
                        validationResult: viewStore.validator.validate(
                            value: viewStore.person.likeArtists,
                            type: .other
                        )
                    )
                    ValidatableTextField(
                        placeholder: String(localized: "favorite-music"),
                        text: viewStore.$person.likeMusics.toUnwrapped(defaultValue: ""),
                        validationResult: viewStore.validator.validate(
                            value: viewStore.person.likeMusics,
                            type: .other
                        )
                    )
                    ValidatableTextField(
                        placeholder: String(localized: "instruments"),
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
                        placeholder: String(localized: "countries-visited"),
                        text: viewStore.$person.travelCountries.toUnwrapped(defaultValue: ""),
                        validationResult: viewStore.validator.validate(
                            value: viewStore.person.travelCountries,
                            type: .other
                        )
                    )
                    ValidatableTextField(
                        placeholder: String(localized: "favorite-place"),
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
        case .note:
            Section {
                TextEditor(text: viewStore.$person.notes.toUnwrapped(defaultValue: ""))
            } header: {
                Text("note-section-title")
            }
        }
    }

    var groupList: some View {
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

    var birthDateRow: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("birth-date")

            Spacer(minLength: 8)

            if viewStore.person.birthdate == nil {
                HStack(alignment: .center, spacing: 0) {
                    Text("not-set")

                    DatePicker("", selection: viewStore.$person.birthdate.toUnwrapped(defaultValue: defaultBirthDate), displayedComponents: [.date])
                }
            } else {
                HStack(alignment: .center, spacing: 4) {
                    DatePicker("", selection: viewStore.$person.birthdate.toUnwrapped(defaultValue: defaultBirthDate), displayedComponents: [.date])

                    Button {
                        viewStore.send(.deleteBirthdateButtonTapped)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.adaptiveBlue)
                            .imageScale(.medium)
                    }
                    .buttonStyle(.plain)
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
