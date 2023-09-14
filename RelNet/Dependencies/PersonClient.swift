//
//  PersonClient.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/24.
//

import Foundation

import ComposableArchitecture
import FirebaseFirestore
import FirebaseFirestoreSwift

struct PersonClient {

    @Dependency(\.authenticationClient) private static var authenticationClient

    var listenGroups: () async throws -> AsyncThrowingStream<IdentifiedArrayOf<Group>, Error>
    var listenPersons: () async throws -> AsyncThrowingStream<IdentifiedArrayOf<Person>, Error>
    var addGroup: (_ group: Group) throws -> Void
    var addPerson: (_ person: Person) throws -> Void
}

extension DependencyValues {
    var personClient: PersonClient {
        get { self[PersonClient.self] }
        set { self[PersonClient.self] = newValue }
    }
}

extension PersonClient: DependencyKey {
    public static let liveValue = Self(
        listenGroups: {
            AsyncThrowingStream { continuation in
                guard let user = authenticationClient.currentUser() else {
                    continuation.finish(throwing: PersonClientError.notFoundUser)
                    return
                }
                let listener = Firestore.firestore()
                    .collection(FirestorePath.users.rawValue)
                    .document(user.uid)
                    .collection(FirestorePath.groups.rawValue)
                    .addSnapshotListener { querySnapshot, error in
                        if let error {
                            continuation.finish(throwing: PersonClientError.general(error))
                        } else if let querySnapshot {
                            let groups = querySnapshot.documents
                                .compactMap { document -> Group? in
                                    try? document.data(as: Group.self)
                                }
                            continuation.yield(IdentifiedArray(uniqueElements: groups))
                        }
                    }
                continuation.onTermination = { @Sendable _ in
                    listener.remove()
                }
            }
        },
        listenPersons: {
            AsyncThrowingStream { continuation in
                guard let user = authenticationClient.currentUser() else {
                    continuation.finish(throwing: PersonClientError.notFoundUser)
                    return
                }
                let listener = Firestore.firestore()
                    .collection(FirestorePath.users.rawValue)
                    .document(user.uid)
                    .collection(FirestorePath.persons.rawValue)
                    .addSnapshotListener { querySnapshot, error in
                        if let error {
                            continuation.finish(throwing: PersonClientError.general(error))
                        } else if let querySnapshot {
                            let persons = querySnapshot.documents
                                .compactMap { document -> Person? in
                                    try? document.data(as: Person.self)
                                }
                            continuation.yield(IdentifiedArray(uniqueElements: persons))
                        }
                    }
                continuation.onTermination = { @Sendable _ in
                    listener.remove()
                }
            }
        },
        addGroup: { group in
            guard let user = authenticationClient.currentUser() else {
                throw PersonClientError.notFoundUser
            }

            do {
                try db
                    .collection(FirestorePath.users.rawValue)
                    .document(user.uid)
                    .collection(FirestorePath.groups.rawValue)
                    .addDocument(from: group)
            } catch {
                throw PersonClientError.general(error)
            }
        },
        addPerson: { person in
            guard let user = authenticationClient.currentUser() else {
                throw PersonClientError.notFoundUser
            }

            do {
                try db
                    .collection(FirestorePath.users.rawValue)
                    .document(user.uid)
                    .collection(FirestorePath.persons.rawValue)
                    .addDocument(from: person)
            } catch {
                throw PersonClientError.general(error)
            }
        }
    )

    private static let db: Firestore = Firestore.firestore()
}

extension PersonClient: TestDependencyKey {
    static let previewValue = Self(
        listenGroups: {
            // TODO: previewに反映されない
            AsyncThrowingStream { continuation in
                let persons: [Group] = [
                    .mock,
                    .mock
                ]
                continuation.yield(IdentifiedArray(uniqueElements: persons))
                continuation.finish()
            }
        },
        listenPersons: {
            AsyncThrowingStream { continuation in
                let persons: [Person] = [
                    .mock,
                    .mock
                ]
                continuation.yield(IdentifiedArray(uniqueElements: persons))
                continuation.finish()
            }
        },
        addGroup: { _ in},
        addPerson: { _ in}
    )
}

enum PersonClientError: LocalizedError, Sendable {
    case general(Error?)
    case notFoundUser

    var errorDescription: String? {
        switch self {
        case let .general(error):
            return "failed. \(String(describing: error?.localizedDescription))"
        case .notFoundUser:
            return "not found user"
        }
    }
}
