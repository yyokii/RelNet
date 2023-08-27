//
//  PersonList.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/24.
//

import Foundation
import ComposableArchitecture

struct PersonList: Reducer {
    
    struct State: Equatable {
        public init() {}
        var persons: IdentifiedArrayOf<Person> = []
    }
    
    enum Action: Equatable {
        case listen
        case listenPersonsResponse(TaskResult<IdentifiedArrayOf<Person>>)
    }

    @Dependency(\.personClient) private var personClient

    public var body: Reduce<State, Action> {
        Reduce { state, action in
            switch action {
            case .listen:
                return .run { send in
                    for try await result in try await self.personClient.listen("aufguss") {
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
    }
}
