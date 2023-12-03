//
//  PersonDetail.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/27.
//

import ComposableArchitecture
import SwiftUI

struct PersonDetail: Reducer {

    struct State: Equatable {
        @PresentationState var destination: Destination.State?
        var person: Person
        let groups: IdentifiedArrayOf<Group>
    }

    enum Action: TCAFeatureAction, Equatable, Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        case destination(PresentationAction<Destination.Action>)

        enum ViewAction: Equatable {
            case cancelEditButtonTapped
            case deleteButtonTapped
            case doneEditingButtonTapped
            case editButtonTapped
        }

        enum InternalAction: Equatable {
            case deletePersonResult(TaskResult<String>)
            case editPersonResult(TaskResult<Person>)
        }

        enum DelegateAction: Equatable {
            case deletePerson(String)
            case updatePerson(Person)
        }
    }

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.personClient) private var personClient

    struct Destination: Reducer {
        enum State: Equatable {
            case alert(AlertState<Action.Alert>)
            case edit(PersonForm.State)
        }
        enum Action: Equatable, Sendable {
            case alert(Alert)
            case edit(PersonForm.Action)

            enum Alert {
                case confirmDeletion
            }
        }
        var body: some ReducerOf<Self> {
            Scope(state: /State.edit, action: /Action.edit) {
                PersonForm()
            }
        }
    }

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .view(viewAction):
                switch viewAction {
                case .cancelEditButtonTapped:
                    state.destination = nil
                    return .none

                case .deleteButtonTapped:
                    state.destination = .alert(.deletePerson)
                    return .none

                case .doneEditingButtonTapped:
                    guard case let .some(.edit(editState)) = state.destination
                    else { return .none }

                    let person = editState.person

                    return .run { send in
                        await send(
                            .internal(
                                .editPersonResult(
                                    await TaskResult {
                                        try self.personClient.updatePerson(person)
                                    }
                                )
                            )
                        )
                    }

                case .editButtonTapped:
                    state.destination = .edit(PersonForm.State(person: state.person, groups: state.groups))
                    return .none
                }

            case let .internal(internalAction):
                switch internalAction {
                case let .deletePersonResult(.success(id)):
                    print("📝 success delete person")
                    return .run { send in
                        await dismiss()
                        await send(.delegate(.deletePerson(id)))
                    }

                case .deletePersonResult(.failure(_)):
                    print("📝 failed delete person")
                    return .none

                case let .editPersonResult(.success(person)):
                    print("📝 success edit person")
                    state.person = person
                    state.destination = nil
                    return .run { send in
                        await send(.delegate(.updatePerson(person)))
                    }

                case .editPersonResult(.failure(_)):
                    print("📝 failed edit person")
                    return .none
                }

            case let .destination(.presented(.alert(alertAction))):
                switch alertAction {
                case .confirmDeletion:
                    guard let id = state.person.id else {
                        return .none
                    }

                    return .run { send in
                        await send(
                            .internal(
                                .deletePersonResult(
                                    await TaskResult {
                                        try personClient.deletePerson(id)
                                    }
                                )
                            )
                        )
                    }
                }

            case .destination:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }
}

struct PersonDetailView: View {
    let store: StoreOf<PersonDetail>

    var birthdateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    struct ViewState: Equatable {
        let person: Person
        // Personに設定されているgroupのname配列
        let groupNames: [String]

        init(state: PersonDetail.State) {
            self.person = state.person
            self.groupNames = state.person.groupIDs.compactMap { groupID in
                state.groups.first(where: { $0.id == groupID })?.name
            }
        }
    }

    var body: some View {
        WithViewStore(self.store, observe: ViewState.init) { viewStore in
            VStack(alignment: .leading, spacing: 12) {
                List {
                    if !viewStore.groupNames.isEmpty {
                        VStack {
                            groupList
                        }
                        .listRowBackground(Color.clear)
                        .offset(x: -18)
                    }

                    Section {
                        textRowItem(symbolName: "face.smiling", iconColor: .yellow, title: "ニックネーム", text: viewStore.person.nickname ?? "")
                        textRowItem(symbolName: "calendar", iconColor: .red, title: "誕生日", text: makeText(for: viewStore.person.birthdate))
                        textRowItem(symbolName: "house", iconColor: .green, title: "住所", text: viewStore.person.address ?? "")
                        textRowItem(symbolName: "heart", iconColor: .orange, title: "趣味", text: viewStore.person.hobbies ?? "")
                        textRowItem(symbolName: "hand.thumbsup", iconColor: .pink, title: "好き", text: viewStore.person.likes ?? "")
                        textRowItem(symbolName: "hand.thumbsdown", iconColor: .gray, title: "苦手", text: viewStore.person.dislikes ?? "")
                    } header: {
                        Text("Basic Info")
                    }

                    Section {
                        textRowItem(symbolName: "heart", iconColor: .purple, title: "両親", text: viewStore.person.parents ?? "")
                        textRowItem(symbolName: "person.2", iconColor: .orange, title: "兄弟姉妹", text: viewStore.person.sibling ?? "")
                        textRowItem(symbolName: "tortoise", iconColor: .teal, title: "ペット", text: viewStore.person.pets ?? "")
                    } header: {
                        Text("Family")
                    }

                    Section {
                        textRowItem(symbolName: "hand.thumbsup", iconColor: .pink, title: "好き", text: viewStore.person.likeFoods ?? "")
                        textRowItem(symbolName: "eyes", iconColor: .teal, title: "アレルギー", text: viewStore.person.allergies ?? "")
                        textRowItem(symbolName: "hand.thumbsdown", iconColor: .gray, title: "苦手", text: viewStore.person.dislikeFoods ?? "")
                    } header: {
                        Text("Food")
                    }

                    Section {
                        textRowItem(symbolName: "rectangle.3.group", iconColor: .orange, title: "好きなジャンル", text: viewStore.person.likeMusicCategories ?? "")
                        textRowItem(symbolName: "music.mic", iconColor: .indigo, title: "好きなアーティスト", text: viewStore.person.likeArtists ?? "")
                        textRowItem(symbolName: "music.note", iconColor: .pink, title: "好きな曲", text: viewStore.person.likeMusics ?? "")
                        textRowItem(symbolName: "guitars", iconColor: .purple, title: "できる楽器", text: viewStore.person.playableInstruments ?? "")
                    } header: {
                        Text("Music")
                    }

                    Section {
                        textRowItem(symbolName: "airplane", iconColor: .orange, title: "行ったことある国", text: viewStore.person.travelCountries ?? "")
                        textRowItem(symbolName: "mappin", iconColor: .green, title: "思い出の場所", text: viewStore.person.favoriteLocations ?? "")
                    } header: {
                        Text("Travel")
                    }
                }
            }
            .navigationTitle(viewStore.person.name)
            .toolbar {
                headerMenu
            }
            .alert(
                store: self.store.scope(state: \.$destination, action: { .destination($0) }),
                state: /PersonDetail.Destination.State.alert,
                action: PersonDetail.Destination.Action.alert
            )
            .sheet(
                store: self.store.scope(state: \.$destination, action: { .destination($0) }),
                state: /PersonDetail.Destination.State.edit,
                action: PersonDetail.Destination.Action.edit
            ) { store in
                NavigationStack {
                    PersonFormView(store: store)
                        .navigationTitle(viewStore.person.name)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    viewStore.send(.view(.cancelEditButtonTapped))
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    viewStore.send(.view(.doneEditingButtonTapped))
                                }
                            }
                        }
                }
            }
        }
    }
}

private extension PersonDetailView {
    func makeText(for birthdate: Date?) -> String {
        if let birthdate {
            return birthdateFormatter.string(from: birthdate)
        } else {
            return ""
        }
    }

    var headerMenu: some View {
        Menu {
            HapticButton {
                store.send(.view(.editButtonTapped))
            } label: {
                HStack {
                    Text("編集する")
                    Image(systemName: "pencil")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
            }

            HapticButton {
                store.send(.view(.deleteButtonTapped))
            } label: {
                Text("削除する")
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 20))
                .foregroundColor(.primary)
        }
    }

    var groupList: some View {
        WithViewStore(self.store, observe: ViewState.init) { viewStore in
            FlowLayout(alignment: .leading, spacing: 8) {
                ForEach(viewStore.groupNames.indices, id: \.self) { index in
                    Text(viewStore.groupNames[index])
                        .groupItemText()
                }
            }
        }
    }

    // TODO: これは別UIでもいいかも
    func lastContactedRow(dateString: String) -> some View {
        textRowItem(symbolName: "figure.wave", iconColor: .brown, title: "最後に会った日", text: dateString)
    }

    func textRowItem(symbolName: String, iconColor: Color, title: String, text: String) -> some View {
        HStack(alignment: .center, spacing: 24) {
            RoundedIconAndTitle(symbolName: symbolName, iconColor: iconColor, title: title)
            Text(text)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

private extension AlertState where Action == PersonDetail.Destination.Action.Alert {
    static let deletePerson = Self {
        TextState("Delete?")
    } actions: {
        ButtonState(role: .destructive, action: .confirmDeletion) {
            TextState("Yes")
        }
        ButtonState(role: .cancel) {
            TextState("Cancel")
        }
    } message: {
        TextState("Are you sure you want to delete this?")
    }
}

#if DEBUG

    let PreviewPersonDetailView: some View = NavigationStack {
        PersonDetailView(
            store: Store(initialState: PersonDetail.State(person: .mock(), groups: .init(uniqueElements: [.mock()]))) {
                PersonDetail()
            }
        )
    }

    #Preview("light") {
        PreviewPersonDetailView
            .environment(\.colorScheme, .light)
    }

    #Preview("dark") {
        PreviewPersonDetailView
            .environment(\.colorScheme, .dark)
    }

#endif
