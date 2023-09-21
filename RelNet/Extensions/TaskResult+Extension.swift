//
//  TaskResult+Extension.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/17.
//

import ComposableArchitecture

// reference: https://qiita.com/Ryu0118/items/e1ce61f48b6b3797c5da
public struct VoidSuccess: Codable, Sendable, Hashable {
  public init() {}
}

extension TaskResult where Success == VoidSuccess {
  public init(catching body: @Sendable () async throws -> Void) async {
    do {
      try await body()
      self = .success(VoidSuccess())
    } catch {
      self = .failure(error)
    }
  }
}
