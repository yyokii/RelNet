//
//  GroupList.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/19.
//

import SwiftUI

import ComposableArchitecture

struct GroupsList: Reducer {

    struct State: Equatable {
        @PresentationState var destination: Destination.State?
        var groups: IdentifiedArrayOf<Group>
    }

    enum Action: Equatable {
        case destination(PresentationAction<Destination.Action>)
        case groupItemTapped(Group)
    }

    struct Destination: Reducer {
        enum State: Equatable {
            case groupDetail(GroupDetail.State)
        }

        enum Action: Equatable {
            case groupDetail(GroupDetail.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: /State.groupDetail, action: /Action.groupDetail) {
                GroupDetail()
            }
        }
    }

    @Dependency(\.personClient) private var personClient

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .destination(.presented(.groupDetail(.deleteGroupResult(.success(deletedGroupId))))):
                guard let index = state.groups.firstIndex(where: { $0.id == deletedGroupId }) else {
                    return .none
                }

                state.groups.remove(at: index)
                return .none

            case let .destination(.presented(.groupDetail(.editGroupResult(.success(updatedGroup))))):
                guard let index = state.groups.firstIndex(where: { $0.id == updatedGroup.id }) else {
                    return .none
                }

                state.groups[index] = updatedGroup
                return .none

            case .destination:
                return .none

            case let .groupItemTapped(group):
                state.destination = .groupDetail(.init(group: group))
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
            ScrollView {
                LazyVStack {
                    ForEach(viewStore.state) { group in
                        Button {
                            viewStore.send(.groupItemTapped(group))
                        } label: {
                            GroupCard(group: group)
                        }
                    }
                }
            }
            .navigationDestination(
                store: store.scope(state: \.$destination, action: { .destination($0) }),
                state: /GroupsList.Destination.State.groupDetail,
                action: GroupsList.Destination.Action.groupDetail
            ) {
                GroupDetailView(store: $0)
            }
        }
    }
}

struct GroupList_Previews: PreviewProvider {
    static var previews: some View {
        GroupsListView(
            store: Store(initialState: GroupsList.State(groups: .init(uniqueElements: [.mock, .mock]))) {
                GroupsList()
            }
        )
    }
}

