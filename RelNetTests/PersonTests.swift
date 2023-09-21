//
//  PersonTests.swift
//  RelNetTests
//
//  Created by Higashihara Yoki on 2023/09/22.
//

import XCTest
@testable import RelNet

final class PersonTests: XCTestCase {

    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func testLastNameFuriganaInitial() {
        let person = Person(lastName: "田中", lastNameFurigana: "たなか")
        XCTAssertEqual(person.nameInitial, "た")
    }

    func testFirstNameFuriganaInitial() {
        let person = Person(firstName: "太郎", firstNameFurigana: "たろう")
        XCTAssertEqual(person.nameInitial, "た")
    }

    func testKanjiLastNameInitialReturnsOther() {
        let person = Person(lastName: "田中")
        XCTAssertEqual(person.nameInitial, "その他")
    }

    func testLastNameInitial() {
        let person = Person(lastName: "Tanaka")
        XCTAssertEqual(person.nameInitial, "T")
    }

    func testFirstNameInitial() {
        let person = Person(firstName: "Taro")
        XCTAssertEqual(person.nameInitial, "T")
    }

    func testKanjiNicknameInitialReturnsOther() {
        let person = Person(nickname: "田中太郎")
        XCTAssertEqual(person.nameInitial, "その他")
    }

    func testNumericNicknameInitialReturnsOther() {
        let person = Person(nickname: "123Taro")
        XCTAssertEqual(person.nameInitial, "その他")
    }

    func testSymbolicNicknameInitialReturnsOther() {
        let person = Person(nickname: "!Taro")
        XCTAssertEqual(person.nameInitial, "!")
    }

    func testNicknameInitial() {
        let person = Person(nickname: "Taro")
        XCTAssertEqual(person.nameInitial, "T")
    }

    func testEmptyNameReturnsOther() {
        let person = Person()
        XCTAssertEqual(person.nameInitial, "その他")
    }
}

