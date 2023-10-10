//
//  TCAFeatureAction.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/10/10.
//

protocol TCAFeatureAction {
    associatedtype ViewAction
    associatedtype InternalAction
    associatedtype DelegateAction

    static func view(_: ViewAction) -> Self
    static func `internal`(_: InternalAction) -> Self
    static func delegate(_: DelegateAction) -> Self
}
