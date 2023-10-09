//
//  PersonDetail.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/27.
//

import SwiftUI

import ComposableArchitecture

struct PersonDetail: Reducer {

    struct State: Equatable {
        @PresentationState var destination: Destination.State?
        var person: Person
        let groups: IdentifiedArrayOf<Group>
    }

    enum Action: Equatable, Sendable {
        // User Action
        case cancelEditButtonTapped
        case deleteButtonTapped
        case doneEditingButtonTapped
        case editButtonTapped

        // Other Action
        case destination(PresentationAction<Destination.Action>)
        case deletePersonResult(TaskResult<String>)
        case editPersonResult(TaskResult<Person>)
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
            case .cancelEditButtonTapped:
                state.destination = nil
                return .none

            case .deleteButtonTapped:
                state.destination = .alert(.deletePerson)
                return .none

            case let .destination(.presented(.alert(alertAction))):
                switch alertAction {
                case .confirmDeletion:
                    guard let id = state.person.id else {
                        return .none
                    }

                    return .run { send in
                        await send(
                            .deletePersonResult(
                                await TaskResult {
                                    try personClient.deletePerson(id)
                                }
                            )
                        )
                    }
                }

            case .doneEditingButtonTapped:
                guard case let .some(.edit(editState)) = state.destination
                else { return .none }

                let person = editState.person

                return .run { send in
                    await send (
                        .editPersonResult(
                            await TaskResult {
                                try  self.personClient.updatePerson(person)
                            }
                        )
                    )
                }

            case .editButtonTapped:
                state.destination = .edit(PersonForm.State(person: state.person, groups: state.groups))
                return .none

            case .destination:
                return .none

            case .deletePersonResult(.success(_)):
                print("📝 success delete person")
                return .run { _ in
                    await dismiss()
                }

            case .deletePersonResult(.failure(_)):
                print("📝 failed delete person")
                return .none

            case let .editPersonResult(.success(person)):
                print("📝 success edit person")
                state.person = person
                state.destination = nil
                return .none

            case .editPersonResult(.failure(_)):
                print("📝 failed edit person")
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

    struct ViewState: Equatable {
        let person: Person
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
            List {
                Section {
                    if !viewStore.person.nickname.isEmpty {
                        nicknameRow("ニックネーム")
                    }
                    birthdateRow(dateString: "2000/09/24")
                    addressRow(viewStore.person.address ?? "")
                    hobbiesRow(viewStore.person.hobbies)
                    likesRow(viewStore.person.likes)
                    dislikesRow(viewStore.person.dislikes)
                    lastContactedRow(dateString: "2020/02/02")
                } header: {
                    Text("Basic Info")
                }

                if !viewStore.person.groupIDs.isEmpty {
                    Section {
                        ForEach(viewStore.groupNames.indices, id: \.self) { index in
                            Text(viewStore.groupNames[index])
                        }
                    } header: {
                        Text("Group")
                    }
                }

                Section {
                    Button("Delete") {
                        viewStore.send(.deleteButtonTapped)
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(viewStore.person.name)
            .toolbar {
                Button("Edit") {
                    viewStore.send(.editButtonTapped)
                }
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
                        .navigationTitle(viewStore.person.firstName)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    viewStore.send(.cancelEditButtonTapped)
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    viewStore.send(.doneEditingButtonTapped)
                                }
                            }
                        }
                }
            }
        }
    }
}

private extension PersonDetailView {
    func nicknameRow(_ name: String) -> some View {
        textRowItem(symbolName: "face.smiling", iconColor: .yellow, title: "ニックネーム", text: name)
    }

    func birthdateRow(dateString: String) -> some View {
        textRowItem(symbolName: "calendar", iconColor: .red, title: "誕生日", text: dateString)
    }

    func addressRow(_ address: String) -> some View {
        textRowItem(symbolName: "house", iconColor: .green, title: "住所", text: address)
    }

    func hobbiesRow(_ hobbies: String) -> some View {
        textRowItem(symbolName: "heart", iconColor: .orange, title: "趣味", text: hobbies)
    }

    func likesRow(_ likes: String) -> some View {
        textRowItem(symbolName: "hand.thumbsup", iconColor: .indigo, title: "好きなもの", text: likes)
    }

    func dislikesRow(_ dislikes: String) -> some View {
        textRowItem(symbolName: "hand.thumbsdown", iconColor: .gray, title: "苦手なもの", text: dislikes)
    }

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

struct PersonDetail_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PersonDetailView(
                store: Store(initialState: PersonDetail.State(person: .mock, groups: .init(uniqueElements: [.mock]))) {
                    PersonDetail()
                }
            )
        }
    }
}
