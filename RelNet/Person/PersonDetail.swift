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
        let personValidator: PersonInputValidator = .init()
    }

    enum Action: TCAFeatureAction, Equatable, Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        case destination(PresentationAction<Destination.Action>)

        enum ViewAction: Equatable {
            case cancelEditButtonTapped
            case deleteButtonTapped
            case editButtonTapped
        }

        enum InternalAction: Equatable {
            case deletePersonResult(TaskResult<String>)
        }

        enum DelegateAction: Equatable {
            case personDeleted(String)
            case personUpdated(Person)
        }
    }

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.personClient) private var personClient

    struct Destination: Reducer {
        enum State: Equatable {
            case alert(AlertState<Action.Alert>)
            case personForm(PersonForm.State)
        }
        enum Action: Equatable, Sendable {
            case alert(Alert)
            case personForm(PersonForm.Action)

            enum Alert {
                case confirmDeletion
            }
        }
        var body: some ReducerOf<Self> {
            Scope(state: /State.personForm, action: /Action.personForm) {
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

                case .editButtonTapped:
                    state.destination = .personForm(PersonForm.State(person: state.person, groups: state.groups, mode: .edit))
                    return .none
                }

            case let .internal(internalAction):
                switch internalAction {
                case let .deletePersonResult(.success(id)):
                    print("📝 success delete person")
                    return .send(.delegate(.personDeleted(id)))

                case .deletePersonResult(.failure(_)):
                    print("📝 failed delete person")
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

            case let .destination(.presented(.personForm(.delegate(.personUpdated(person))))):
                state.destination = nil
                state.person = person
                return .send(.delegate(.personUpdated(person)))

            case .delegate, .destination:
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
                        Text("basic-info-section-title")
                    }

                    Section {
                        textRowItem(symbolName: "heart", iconColor: .purple, title: "両親", text: viewStore.person.parents ?? "")
                        textRowItem(symbolName: "person.2", iconColor: .orange, title: "兄弟姉妹", text: viewStore.person.sibling ?? "")
                        textRowItem(symbolName: "tortoise", iconColor: .teal, title: "ペット", text: viewStore.person.pets ?? "")
                    } header: {
                        Text("family-section-title")
                    }

                    Section {
                        textRowItem(symbolName: "hand.thumbsup", iconColor: .pink, title: "好き", text: viewStore.person.likeFoods ?? "")
                        textRowItem(symbolName: "hand.thumbsdown", iconColor: .gray, title: "苦手", text: viewStore.person.dislikeFoods ?? "")
                        textRowItem(symbolName: "eyes", iconColor: .teal, title: "アレルギー", text: viewStore.person.allergies ?? "")

                    } header: {
                        Text("food-section-title")
                    }

                    Section {
                        textRowItem(symbolName: "rectangle.3.group", iconColor: .orange, title: "好きなジャンル", text: viewStore.person.likeMusicCategories ?? "")
                        textRowItem(symbolName: "music.mic", iconColor: .indigo, title: "好きなアーティスト", text: viewStore.person.likeArtists ?? "")
                        textRowItem(symbolName: "music.note", iconColor: .pink, title: "好きな曲", text: viewStore.person.likeMusics ?? "")
                        textRowItem(symbolName: "guitars", iconColor: .purple, title: "できる楽器", text: viewStore.person.playableInstruments ?? "")
                    } header: {
                        Text("music-section-title")
                    }

                    Section {
                        textRowItem(symbolName: "airplane", iconColor: .orange, title: "行ったことある国", text: viewStore.person.travelCountries ?? "")
                        textRowItem(symbolName: "mappin", iconColor: .green, title: "思い出の場所", text: viewStore.person.favoriteLocations ?? "")
                    } header: {
                        Text("travel-section-title")
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
                state: /PersonDetail.Destination.State.personForm,
                action: PersonDetail.Destination.Action.personForm
            ) { store in
                NavigationView {
                    PersonFormView(store: store)
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
                    Text("edit-button-title")
                    Image(systemName: "pencil")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
            }

            HapticButton {
                store.send(.view(.deleteButtonTapped))
            } label: {
                Text("delete-button-title")
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
        TextState("delete-alert-title")
    } actions: {
        ButtonState(role: .destructive, action: .confirmDeletion) {
            TextState("yes")
        }
        ButtonState(role: .cancel) {
            TextState("cancel")
        }
    } message: {
        TextState("")
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
