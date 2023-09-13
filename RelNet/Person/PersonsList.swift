//
//  PersonsList.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/24.
//

import Foundation
import SwiftUI

import ComposableArchitecture

struct PersonsList: Reducer {

    struct State: Equatable {
        @PresentationState var destination: Destination.State?
        var persons: IdentifiedArrayOf<Person> = []

        init(
            destination: Destination.State? = nil
        ) {
            self.destination = destination
        }
    }

    enum Action: Equatable {
        case addPersonButtonTapped
        case confirmAddPersonButtonTapped
        case destination(PresentationAction<Destination.Action>)
        case dismissAddPersonButtonTapped
        case listen
        case listenPersonsResponse(TaskResult<IdentifiedArrayOf<Person>>)
    }

    struct Destination: Reducer {
        enum State: Equatable {
            case add(PersonForm.State)
        }

        enum Action: Equatable {
            case add(PersonForm.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: /State.add, action: /Action.add) {
                PersonForm()
            }
        }
    }

    @Dependency(\.authenticationClient) private var authenticationClient
    @Dependency(\.personClient) private var personClient

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .addPersonButtonTapped:
                state.destination = .add(PersonForm.State(person: Person()))
                return .none

            case .confirmAddPersonButtonTapped:
                guard case let .some(.add(editState)) = state.destination
                else { return .none }
                let person = editState.person
                state.persons.append(person)
                state.destination = nil
                return .none

            case .destination:
                return .none

            case .dismissAddPersonButtonTapped:
                state.destination = nil
                return .none

            case .listen:
                return .run { send in
                    guard let user = self.authenticationClient.currentUser() else {
                        return
                    }

                    for try await result in try await self.personClient.listenPersons(user.uid) {
                        await send(.listenPersonsResponse(.success(result)))
                    }
                } catch: { error, send in
                    await send(.listenPersonsResponse(.failure(error)))
                }

            case let .listenPersonsResponse(.success(persons)):
                state.persons = persons
                return .none

            case let .listenPersonsResponse(.failure(error)):
                print(error.localizedDescription)
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }
}

struct PersonsListView: View {
    let store: StoreOf<PersonsList>

    var body: some View {
        WithViewStore(self.store, observe: \.persons) { viewStore in
            List {
                ForEach(viewStore.state) { person in
                    NavigationLink(
                        state: AppFeature.Path.State.personDetail(PersonDetail.State(person: person))
                    ) {
                        CardView(person: person)
                    }
                }
            }
            .toolbar {
                Button {
                    viewStore.send(.addPersonButtonTapped)
                } label: {
                    Image(systemName: "plus")
                }
            }
            .navigationTitle("Persons")
            .task {
                await viewStore.send(.listen).finish()
            }
            .sheet(
                store: self.store.scope(state: \.$destination, action: { .destination($0) }),
                state: /PersonsList.Destination.State.add,
                action: PersonsList.Destination.Action.add
            ) { store in
                NavigationStack {
                    PersonFormView(store: store)
                }
            }
        }
    }
}

struct CardView: View {
    let person: Person

    var body: some View {
        VStack(alignment: .leading) {
            Text(self.person.name)
                .font(.headline)
        }
        .padding()
        .foregroundColor(Color.cyan)
    }
}

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}

extension LabelStyle where Self == TrailingIconLabelStyle {
    static var trailingIcon: Self { Self() }
}

struct PersonsList_Previews: PreviewProvider {
    static var previews: some View {
        PersonsListView(
            store: Store(initialState: PersonsList.State()) {
                PersonsList()
            }
        )
    }
}
