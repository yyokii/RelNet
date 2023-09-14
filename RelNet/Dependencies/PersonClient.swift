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
    // TODO: ID渡すのではなく、処理の中で参照した方がシンプルかもしれない
    var listenGroups: (_ userID: String) async throws -> AsyncThrowingStream<IdentifiedArrayOf<Group>, Error>
    var listenPersons: (_ userID: String) async throws -> AsyncThrowingStream<IdentifiedArrayOf<Person>, Error>
    var addGroup: (_ group: Group, _ userID: String) throws -> Void
    var addPerson: (_ person: Person, _ userID: String) throws -> Void
}

extension DependencyValues {
    var personClient: PersonClient {
        get { self[PersonClient.self] }
        set { self[PersonClient.self] = newValue }
    }
}

extension PersonClient: DependencyKey {
    public static let liveValue = Self(
        listenGroups: { userID in
            AsyncThrowingStream { continuation in
                let listener = Firestore.firestore()
                    .collection(FirestorePath.users.rawValue)
                    .document(userID)
                    .collection(FirestorePath.groups.rawValue)
                    .addSnapshotListener { querySnapshot, error in
                        if let error {
                            continuation.finish(throwing: error)
                        }
                        if let querySnapshot {
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
        listenPersons: { userID in
            AsyncThrowingStream { continuation in
                let listener = Firestore.firestore()
                    .collection(FirestorePath.users.rawValue)
                    .document(userID)
                    .collection(FirestorePath.persons.rawValue)
                    .addSnapshotListener { querySnapshot, error in
                        if let error {
                            continuation.finish(throwing: error)
                        }
                        if let querySnapshot {
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
        addGroup: { group, userID in
            do {
                try db
                    .collection(FirestorePath.users.rawValue)
                    .document(userID)
                    .collection(FirestorePath.groups.rawValue)
                    .addDocument(from: group)
            } catch {
                throw PersonClientError.general
            }
        },
        addPerson: { person, userID in
            do {
                try db
                    .collection(FirestorePath.users.rawValue)
                    .document(userID)
                    .collection(FirestorePath.persons.rawValue)
                    .addDocument(from: person)
            } catch {
                throw PersonClientError.general
            }
        }
    )

    private static let db: Firestore = Firestore.firestore()
}

extension PersonClient: TestDependencyKey {
    static let previewValue = Self(
        listenGroups: { _ in
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
        listenPersons: { _ in
            AsyncThrowingStream { continuation in
                let persons: [Person] = [
                    .mock,
                    .mock
                ]
                continuation.yield(IdentifiedArray(uniqueElements: persons))
                continuation.finish()
            }
        },
        addGroup: { _, _ in},
        addPerson: { _, _ in}
    )
}

enum PersonClientError: Equatable, LocalizedError, Sendable {
    case general

    var errorDescription: String? {
        switch self {
        case .general:
            return "failed"
        }
    }
}
