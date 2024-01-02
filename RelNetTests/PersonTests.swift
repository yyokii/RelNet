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

    func testHiraganaNameInitial() {
        let person = Person(name: "あああ")
        XCTAssertEqual(person.nameInitial, "あ")
    }

    func testKatakanaNameInitial() {
        let person = Person(name: "アイウエオ")
        XCTAssertEqual(person.nameInitial, "あ")
    }

    func testFuriganaInitial() {
        let person = Person(name: "田中", furigana: "たなか")
        XCTAssertEqual(person.nameInitial, "た")
    }

    func testKanjiNameInitial() {
        let person = Person(name: "田中")
        XCTAssertEqual(person.nameInitial, "その他")
    }

    func testEnglishNameInitial() {
        let person = Person(name: "Tanaka")
        XCTAssertEqual(person.nameInitial, "T")
    }
}
