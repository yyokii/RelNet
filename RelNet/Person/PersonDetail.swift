//
//  PersonDetail.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/27.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct PersonDetail {
    struct State: Equatable {
        @PresentationState var destination: Destination.State?
        @BindingState var selectedContentType: ContentTypeSegmentedPicker.ContentType = .list

        var person: Person
        var groupNames: [String] {
            person.groupIDs.compactMap { groupID in
                groups.first(where: { $0.id == groupID })?.name
            }
        }
        let groups: IdentifiedArrayOf<Group>
        let personValidator: PersonInputValidator = .init()

        init(person: Person, groups: IdentifiedArrayOf<Group>) {
            self.person = person
            self.groups = groups
        }
    }

    enum Action: TCAFeatureAction, BindableAction, Equatable, Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)

        case binding(BindingAction<State>)
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
    @Dependency(\.appClient) private var appClient

    @Reducer
    struct Destination {
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
            Scope(state: \.personForm, action: \.personForm) {
                PersonForm()
            }
        }
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
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
                                        try appClient.deletePerson(id)
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

            case .delegate, .binding, .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            Destination()
        }
    }
}

struct PersonDetailView: View {
    private let store: StoreOf<PersonDetail>
    @ObservedObject private var viewStore: ViewStoreOf<PersonDetail>

    var birthdateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        List {
            if !viewStore.groupNames.isEmpty {
                Section {
                    groupList
                } header: {
                    Text("group-section-title")
                }
                .listRowBackground(Color.clear)
            }

            ContentTypeSegmentedPicker(selectedContentType: viewStore.$selectedContentType)
                .listRowBackground(Color.clear)

            personContent
        }
        .navigationTitle(viewStore.person.name)
        .toolbar {
            headerMenu
        }
        .alert(
            store: self.store.scope(state: \.$destination.alert, action: \.destination.alert)
        )
        .sheet(
            store: self.store.scope(state: \.$destination.personForm, action: \.destination.personForm)
        ) { store in
            NavigationView {
                PersonFormView(store: store)
            }
        }
    }

    init(store: StoreOf<PersonDetail>) {
        self.store = store
        self.viewStore = ViewStore(self.store, observe: { $0 })
    }
}

private extension PersonDetailView {

    @ViewBuilder
    var personContent: some View {
        switch viewStore.selectedContentType {
        case .list:
            Section {
                textRowItem(symbolName: "face.smiling", iconColor: .yellow, title: String(localized: "nick-name"), text: viewStore.person.nickname ?? "")
                textRowItem(symbolName: "calendar", iconColor: .red, title: String(localized: "birth-date"), text: makeText(for: viewStore.person.birthdate))
                textRowItem(symbolName: "house", iconColor: .green, title: String(localized: "address"), text: viewStore.person.address ?? "")
                textRowItem(symbolName: "heart", iconColor: .orange, title: String(localized: "hobby"), text: viewStore.person.hobbies ?? "")
                textRowItem(symbolName: "hand.thumbsup", iconColor: .pink, title: String(localized: "like"), text: viewStore.person.likes ?? "")
                textRowItem(symbolName: "hand.thumbsdown", iconColor: .gray, title: String(localized: "dislike"), text: viewStore.person.dislikes ?? "")
            } header: {
                Text("basic-info-section-title")
            }

            Section {
                textRowItem(symbolName: "heart", iconColor: .purple, title: String(localized: "parent"), text: viewStore.person.parents ?? "")
                textRowItem(symbolName: "person.2", iconColor: .orange, title: String(localized: "siblings"), text: viewStore.person.sibling ?? "")
                textRowItem(symbolName: "figure.child", iconColor: .teal, title: String(localized: "child"), text: viewStore.person.children ?? "")
                textRowItem(symbolName: "tortoise", iconColor: .teal, title: String(localized: "pet"), text: viewStore.person.pets ?? "")
            } header: {
                Text("family-section-title")
            }

            Section {
                textRowItem(symbolName: "hand.thumbsup", iconColor: .pink, title: String(localized: "like"), text: viewStore.person.likeFoods ?? "")
                textRowItem(symbolName: "hand.thumbsdown", iconColor: .green, title: String(localized: "dislike"), text: viewStore.person.dislikeFoods ?? "")
                textRowItem(symbolName: "eyes", iconColor: .teal, title: String(localized: "allergy"), text: viewStore.person.allergies ?? "")

            } header: {
                Text("food-section-title")
            }

            Section {
                textRowItem(symbolName: "rectangle.3.group", iconColor: .orange, title: String(localized: "favorite-genre"), text: viewStore.person.likeMusicCategories ?? "")
                textRowItem(symbolName: "music.mic", iconColor: .indigo, title: String(localized: "favorite-artist"), text: viewStore.person.likeArtists ?? "")
                textRowItem(symbolName: "music.note", iconColor: .pink, title: String(localized: "favorite-music"), text: viewStore.person.likeMusics ?? "")
                textRowItem(symbolName: "guitars", iconColor: .purple, title: String(localized: "instruments"), text: viewStore.person.playableInstruments ?? "")
            } header: {
                Text("music-section-title")
            }

            Section {
                textRowItem(symbolName: "airplane", iconColor: .orange, title: String(localized: "countries-visited"), text: viewStore.person.travelCountries ?? "")
                textRowItem(symbolName: "mappin", iconColor: .green, title: String(localized: "favorite-place"), text: viewStore.person.favoriteLocations ?? "")
            } header: {
                Text("travel-section-title")
            }
        case .note:
            Section {
                Text(viewStore.person.notes ?? "")
            } header: {
                Text("note-section-title")
            }
        }
    }

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
        FlowLayout(alignment: .leading, spacing: 8) {
            ForEach(viewStore.groupNames.indices, id: \.self) { index in
                Text(viewStore.groupNames[index])
                    .groupItemText()
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
            store: Store(
                initialState:
                    PersonDetail.State(
                        person: .mock(),
                        groups: .init(uniqueElements: [.mock(id: "id-1")])
                    )
            ) {
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
