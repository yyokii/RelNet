//
//  AuthenticationClient.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/04.
//

import Foundation

import ComposableArchitecture

struct AuthenticationClient: Sendable {
  var login: @Sendable (LoginRequest) async throws -> AuthenticationResponse

  init(
    login: @escaping @Sendable (LoginRequest) async throws -> AuthenticationResponse
  ) {
    self.login = login
  }
}

extension DependencyValues {
  var authenticationClient: AuthenticationClient {
    get { self[AuthenticationClient.self] }
    set { self[AuthenticationClient.self] = newValue }
  }
}

extension AuthenticationClient: DependencyKey {
  public static let liveValue = Self(
    login: { request in
      guard request.email.contains("@") && request.password == "password"
      else { throw AuthenticationError.invalidUserPassword }

      try await Task.sleep(nanoseconds: NSEC_PER_SEC)
      return AuthenticationResponse(token: "deadbeef")
    }
  )
}

struct LoginRequest: Sendable {
  public var email: String
  public var password: String

  public init(
    email: String,
    password: String
  ) {
    self.email = email
    self.password = password
  }
}

struct AuthenticationResponse: Equatable, Sendable {
  public var token: String

  public init(
    token: String
  ) {
    self.token = token
  }
}

enum AuthenticationError: Equatable, LocalizedError, Sendable {
  case invalidUserPassword
  case invalidIntermediateToken

  var errorDescription: String? {
    switch self {
    case .invalidUserPassword:
      return "Unknown user or invalid password."
    case .invalidIntermediateToken:
      return "404!! What happened to your token there bud?!?!"
    }
  }
}
