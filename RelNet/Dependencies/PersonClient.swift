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
    var listen: (_ userID: String) async throws -> AsyncThrowingStream<IdentifiedArrayOf<Person>, Error>
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
        listen: { userID in
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

enum PersonClientError: Equatable, LocalizedError, Sendable {
    case general

    var errorDescription: String? {
        switch self {
        case .general:
            return "failed"
        }
    }
}
