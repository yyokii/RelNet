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
        let person = Person(name: "田中", furigana: "たなか")
        XCTAssertEqual(person.nameInitial, "た")
    }

    func testFirstNameFuriganaInitial() {
        let person = Person(name: "太郎", furigana: "たろう")
        XCTAssertEqual(person.nameInitial, "た")
    }

    func testKanjiLastNameInitialReturnsOther() {
        let person = Person(name: "田中")
        XCTAssertEqual(person.nameInitial, "その他")
    }

    func testLastNameInitial() {
        let person = Person(name: "Tanaka")
        XCTAssertEqual(person.nameInitial, "T")
    }

    func testFirstNameInitial() {
        let person = Person(name: "Taro")
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
}
