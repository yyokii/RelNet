//
//  GroupsList.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/29.
//

import Foundation
import SwiftUI

import ComposableArchitecture

struct GroupsList: Reducer {

    struct State: Equatable {
        @PresentationState var destination: Destination.State?
        var groups: IdentifiedArrayOf<Group> = []

        init(
            destination: Destination.State? = nil
        ) {
            self.destination = destination
        }
    }

    enum Action: Equatable {
        case addGroupButtonTapped
        case confirmAddGroupButtonTapped
        case destination(PresentationAction<Destination.Action>)
        case dismissAddGroupButtonTapped
        case listen
        case listenGroupsResponse(TaskResult<IdentifiedArrayOf<Group>>)
    }

    struct Destination: Reducer {
        enum State: Equatable {
            case add(GroupForm.State)
        }

        enum Action: Equatable {
            case add(GroupForm.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: /State.add, action: /Action.add) {
                GroupForm()
            }
        }
    }

    @Dependency(\.authenticationClient) private var authenticationClient
    @Dependency(\.personClient) private var personClient

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .addGroupButtonTapped:
                state.destination = .add(GroupForm.State(group: Group(id: UUID().uuidString)))
                return .none

            case .confirmAddGroupButtonTapped:
                guard case let .some(.add(editState)) = state.destination
                else { return .none }
                let group = editState.group
                state.groups.append(group)
                state.destination = nil
                return .none

            case .destination:
                return .none

            case .dismissAddGroupButtonTapped:
                state.destination = nil
                return .none

            case .listen:
                return .run { send in
                    guard let user = self.authenticationClient.currentUser() else {
                        return
                    }

                    for try await result in try await self.personClient.listenGroups(user.uid) {
                        await send(.listenGroupsResponse(.success(result)))
                    }
                } catch: { error, send in
                    await send(.listenGroupsResponse(.failure(error)))
                }

            case let .listenGroupsResponse(.success(groups)):
                state.groups = groups
                return .none

            case let .listenGroupsResponse(.failure(error)):
                print(error.localizedDescription)
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }
}

struct GroupsListView: View {
    let store: StoreOf<GroupsList>

    var body: some View {
        WithViewStore(self.store, observe: \.groups) { viewStore in
            List {
                ForEach(viewStore.state) { group in
                    NavigationLink(
                        state: AppFeature.Path.State.groupDetail(GroupDetail.State(group: group))
                    ) {
                        GroupCardView(group: group)
                    }
                }
            }
            .toolbar {
                Button {
                    viewStore.send(.addGroupButtonTapped)
                } label: {
                    Image(systemName: "plus")
                }
            }
            .navigationTitle("Goups")
            .task {
                await viewStore.send(.listen).finish()
            }
            .sheet(
                store: self.store.scope(state: \.$destination, action: { .destination($0) }),
                state: /GroupsList.Destination.State.add,
                action: GroupsList.Destination.Action.add
            ) { store in
                NavigationStack {
                    GroupFormView(store: store)
                }
            }
        }
    }
}

struct GroupCardView: View {
    let group: Group

    var body: some View {
        VStack(alignment: .leading) {
            Text(self.group.name)
                .font(.headline)
        }
        .padding()
        .foregroundColor(Color.orange)
    }
}

struct GroupList_Previews: PreviewProvider {
    static var previews: some View {
        GroupsListView(
            store: Store(initialState: GroupsList.State()) {
                GroupsList()
            }
        )
    }
}

