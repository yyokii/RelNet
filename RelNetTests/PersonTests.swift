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
        XCTContext.runActivity(named: "あ段で分別される") { _ in
            let person1 = Person(name: "い")
            XCTAssertEqual(person1.nameInitialForIndex, "あ")
            let person2 = Person(name: "こ")
            XCTAssertEqual(person2.nameInitialForIndex, "か")

        }

        XCTContext.runActivity(named: "濁音") { _ in
            let person3 = Person(name: "が")
            XCTAssertEqual(person3.nameInitialForIndex, "か")
            let person4 = Person(name: "び")
            XCTAssertEqual(person4.nameInitialForIndex, "は")

        }

        XCTContext.runActivity(named: "半濁音") { _ in
            let person5 = Person(name: "ぱ")
            XCTAssertEqual(person5.nameInitialForIndex, "は")
            let person6 = Person(name: "ぽ")
            XCTAssertEqual(person6.nameInitialForIndex, "は")
        }
    }

    func testKatakanaNameInitial() {
        let person = Person(name: "アイウエオ")
        XCTAssertEqual(person.nameInitialForIndex, "あ")
    }

    func testFuriganaInitial() {
        let person = Person(name: "田中", furigana: "たなか")
        XCTAssertEqual(person.nameInitialForIndex, "た")
    }

    func testKanjiNameInitial() {
        let person = Person(name: "田中")
        XCTAssertEqual(person.nameInitialForIndex, String(localized: "other-category-title"))
    }

    func testEnglishNameInitial() {
        let person = Person(name: "Tanaka")
        XCTAssertEqual(person.nameInitialForIndex, "T")
    }
}
