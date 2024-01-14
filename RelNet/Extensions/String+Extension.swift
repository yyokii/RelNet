//
//  String+Extension.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/09/21.
//

import Foundation

extension String {

    /**
     「漢字」、「ひらがな」、「カタカナ」のいずれかがStringに含まれる場合、そのふりがなを表すStringを取得できる
     */
    public var furigana: String {
        // 対象文字列に「漢字」、「ひらがな」、「カタカナ」のいずれかが含まれる場合のみ変換する（[...]: 括弧内の任意の1文字にマッチ）
        let regexString = "[\\p{Script=Han}\\p{Script=Hiragana}\\p{Script=Katakana}]"
        let regex = try! NSRegularExpression(pattern: regexString)
        let regexRange = NSRange(location: 0, length: self.utf16.count)

        guard regex.firstMatch(in: self, options: [], range: regexRange) != nil else {
            return self
        }

        let inputText: NSString = self as NSString
        let furigana = NSMutableString()

        let range: CFRange = CFRangeMake(0, inputText.length)

        // 日本語localeを生成
        let jaLocaleIdentifier: CFLocaleIdentifier = CFLocaleCreateCanonicalLanguageIdentifierFromString(kCFAllocatorDefault, "ja" as CFString)
        let locale: CFLocale = CFLocaleCreate(kCFAllocatorDefault, jaLocaleIdentifier)

        let tokenizer: CFStringTokenizer = CFStringTokenizerCreate(kCFAllocatorDefault, inputText as CFString, range, kCFStringTokenizerUnitWordBoundary, locale)

        var tokenType: CFStringTokenizerTokenType = CFStringTokenizerGoToTokenAtIndex(tokenizer, 0)

        while tokenType != [] {
            // ラテン文字からローマ字に変換することでひらがな表記を取得する
            let latin: CFTypeRef = CFStringTokenizerCopyCurrentTokenAttribute(tokenizer, kCFStringTokenizerAttributeLatinTranscription)

            guard let romanAlphabet: NSMutableString = latin as? NSMutableString else { continue }
            CFStringTransform(romanAlphabet as CFMutableString, nil, kCFStringTransformLatinHiragana, false)

            furigana.append(romanAlphabet as String)
            tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        }

        let hiraganaFurigana = furigana as String
        if let katakanaFurigana = hiraganaFurigana.applyingTransform(.hiraganaToKatakana, reverse: false) {
            return katakanaFurigana
        } else {
            return hiraganaFurigana
        }
    }

    /// Returns the category of 平仮名.
    /// Returns the character itself if no category is found.
    public var hiraganaCategory: String {
        let categories = [
            "あ": "あいうえお",
            "か": "かきくけこがぎぐげござじずぜぞ",
            "さ": "さしすせそざじずぜぞ",
            "た": "たちつてとだぢづでど",
            "な": "なにぬねの",
            "は": "はひふへほばびぶべぼぱぴぷぺぽ",
            "ま": "まみむめも",
            "や": "やゆよ",
            "ら": "らりるれろ",
            "わ": "わをん",
        ]

        for (category, chars) in categories {
            if chars.contains(self) {
                return category
            }
        }
        return self
    }
}
