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

struct PersonClient: Sendable {

    @Dependency(\.authenticationClient) private static var authenticationClient

    var listenGroups: @Sendable () async throws -> AsyncThrowingStream<IdentifiedArrayOf<Group>, Error>
    var listenPersons: @Sendable () async throws -> AsyncThrowingStream<IdentifiedArrayOf<Person>, Error>
    var addGroup: @Sendable (_ group: Group) throws -> Group
    var addPerson: @Sendable (_ person: Person) throws -> Person
    var deleteGroup: @Sendable (_ id: String) throws -> String
    var deletePerson: @Sendable (_ id: String) throws -> String
    var updateGroup: @Sendable (_ group: Group) throws -> Group
    var updatePerson: @Sendable (_ person: Person) throws -> Person
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

                return group
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

                return person
            } catch {
                throw PersonClientError.general(error)
            }
        },
        deleteGroup: { id in
            guard let user = authenticationClient.currentUser() else {
                throw PersonClientError.notFoundUser
            }

            db
                .collection(FirestorePath.users.rawValue)
                .document(user.uid)
                .collection(FirestorePath.groups.rawValue)
                .document(id)
                .delete()

            return id
        },
        deletePerson: { id in
            guard let user = authenticationClient.currentUser() else {
                throw PersonClientError.notFoundUser
            }

            db
                .collection(FirestorePath.users.rawValue)
                .document(user.uid)
                .collection(FirestorePath.persons.rawValue)
                .document(id)
                .delete()

            return id
        },
        updateGroup: { group in
            guard let user = authenticationClient.currentUser() else {
                throw PersonClientError.notFoundUser
            }

            guard let id = group.id else {
                throw PersonClientError.notFoundID
            }

            var updateGroup = group
            updateGroup.updatedAt = Timestamp(date: Date())

            db
                .collection(FirestorePath.users.rawValue)
                .document(user.uid)
                .collection(FirestorePath.groups.rawValue)
                .document(id)
                .setData(updateGroup.toDictionary())

            return group
        },
        updatePerson: { person in
            guard let user = authenticationClient.currentUser() else {
                throw PersonClientError.notFoundUser
            }

            guard let id = person.id else {
                throw PersonClientError.notFoundID
            }

            var updatePerson = person
            updatePerson.updatedAt = Timestamp(date: Date())

            db
                .collection(FirestorePath.users.rawValue)
                .document(user.uid)
                .collection(FirestorePath.persons.rawValue)
                .document(id)
                .setData(updatePerson.toDictionary())

            return person
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
        addGroup: { _ in .mock },
        addPerson: { _ in .mock },
        deleteGroup: { _ in "deletedID" },
        deletePerson: { _ in "deletedID" },
        updateGroup: { _ in .mock },
        updatePerson: { _ in .mock }
    )
}

enum PersonClientError: LocalizedError, Sendable {
    case general(Error?)
    case notFoundID
    case notFoundUser

    var errorDescription: String? {
        switch self {
        case let .general(error):
            return "failed. \(String(describing: error?.localizedDescription))"
        case .notFoundID:
            return "not found id"
        case .notFoundUser:
            return "not found user"
        }
    }
}
