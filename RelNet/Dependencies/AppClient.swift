//
//  AppClient.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/08/24.
//

import ComposableArchitecture
import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

// TODO: AppClient とかにrenameした方がいいかも
struct AppClient: Sendable {

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
    var appClient: AppClient {
        get { self[AppClient.self] }
        set { self[AppClient.self] = newValue }
    }
}

extension AppClient: DependencyKey {
    private static let db: Firestore = Firestore.firestore()

    public static let liveValue = Self(
        listenGroups: {
            AsyncThrowingStream { continuation in
                guard let user = authenticationClient.currentUser() else {
                    print("📝 not found user")
                    continuation.finish(throwing: AppClientError.notFoundUser)
                    return
                }
                print("📝 new listener call")
                let listener = Firestore.firestore()
                    .collection(FirestorePath.users.rawValue)
                    .document(user.uid)
                    .collection(FirestorePath.groups.rawValue)
                    .addSnapshotListener { querySnapshot, error in
                        if let error {
                            continuation.finish(throwing: AppClientError.general(error))
                        } else if let querySnapshot {
                            let groups = querySnapshot.documents
                                .compactMap { document -> Group? in
                                    try? document.data(as: Group.self)
                                }
                                .sorted { (group1, group2) -> Bool in
                                    group1.name < group2.name
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
                    continuation.finish(throwing: AppClientError.notFoundUser)
                    return
                }
                let listener = Firestore.firestore()
                    .collection(FirestorePath.users.rawValue)
                    .document(user.uid)
                    .collection(FirestorePath.persons.rawValue)
                    .addSnapshotListener { querySnapshot, error in
                        if let error {
                            continuation.finish(throwing: AppClientError.general(error))
                        } else if let querySnapshot {
                            let persons = querySnapshot.documents
                                .compactMap { document -> Person? in
                                    try? document.data(as: Person.self)
                                }
                                .sorted { (person1, person2) -> Bool in
                                    person1.name < person2.name
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
                throw AppClientError.notFoundUser
            }

            do {
                try db
                    .collection(FirestorePath.users.rawValue)
                    .document(user.uid)
                    .collection(FirestorePath.groups.rawValue)
                    .addDocument(from: group)

                return group
            } catch {
                throw AppClientError.general(error)
            }
        },
        addPerson: { person in
            guard let user = authenticationClient.currentUser() else {
                throw AppClientError.notFoundUser
            }

            do {
                try db
                    .collection(FirestorePath.users.rawValue)
                    .document(user.uid)
                    .collection(FirestorePath.persons.rawValue)
                    .addDocument(from: person)

                return person
            } catch {
                throw AppClientError.general(error)
            }
        },
        deleteGroup: { id in
            guard let user = authenticationClient.currentUser() else {
                throw AppClientError.notFoundUser
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
                throw AppClientError.notFoundUser
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
                throw AppClientError.notFoundUser
            }

            guard let id = group.id else {
                throw AppClientError.notFoundID
            }

            var updateGroup = group
            updateGroup.updatedAt = Timestamp(date: Date())

            do {
                try db
                    .collection(FirestorePath.users.rawValue)
                    .document(user.uid)
                    .collection(FirestorePath.groups.rawValue)
                    .document(id)
                    .setData(from: updateGroup)
            } catch {
                throw AppClientError.failedToUpdate(error)
            }
            return group
        },
        updatePerson: { person in
            guard let user = authenticationClient.currentUser() else {
                throw AppClientError.notFoundUser
            }

            guard let id = person.id else {
                throw AppClientError.notFoundID
            }

            var updatePerson = person
            updatePerson.updatedAt = Timestamp(date: Date())

            do {
                try db
                    .collection(FirestorePath.users.rawValue)
                    .document(user.uid)
                    .collection(FirestorePath.persons.rawValue)
                    .document(id)
                    .setData(from: updatePerson)
            } catch {
                throw AppClientError.failedToUpdate(error)
            }
            return person
        }
    )
}

enum AppClientError: LocalizedError, Sendable {
    case general(Error?)

    case failedToUpdate(Error?)
    case notFoundID
    case notFoundUser

    var errorDescription: String? {
        switch self {
        case let .general(error):
            return "failed. \(String(describing: error?.localizedDescription))"
        case let .failedToUpdate(error):
            return "failed to update. \(String(describing: error?.localizedDescription))"
        case .notFoundID:
            return "not found id"
        case .notFoundUser:
            return "not found user"
        }
    }
}

#if DEBUG
    extension AppClient: TestDependencyKey {
        static let previewValue = Self(
            listenGroups: {
                AsyncThrowingStream { continuation in
                    let persons: [Group] = [
                        .mock(id: "id-1"),
                        .mock(id: "id-2"),
                    ]
                    continuation.yield(IdentifiedArray(uniqueElements: persons))
                    continuation.finish()
                }
            },
            listenPersons: {
                AsyncThrowingStream { continuation in
                    let persons: [Person] = [
                        .mock(id: "id-1"),
                        .mock(id: "id-2"),
                    ]
                    continuation.yield(IdentifiedArray(uniqueElements: persons))
                    continuation.finish()
                }
            },
            addGroup: { _ in .mock() },
            addPerson: { _ in .mock() },
            deleteGroup: { _ in "deletedID" },
            deletePerson: { _ in "deletedID" },
            updateGroup: { _ in .mock() },
            updatePerson: { _ in .mock() }
        )
    }
#endif
