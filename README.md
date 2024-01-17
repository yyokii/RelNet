Simple Friend List App for iOS

![app-screen-shot](https://github.com/yyokii/RelNet/assets/20992687/6e6006bc-4495-44d7-a817-db29c78409aa)

## 📖 Features

* Sign up/in
* Add group
* Add person

## 🥞 Teck Stacks

* SwiftUI
* The Composable Architecture
* Xcode Cloud
* Firebase
  * Firebase Auth
  * Firestore
  * Firebase Crashlytics
  * Cloud Functions for Firebase

## Dev memo

* 軽微な修正だが、SwiftUIでコンパイル時間が長くエラーが把握できないケースがあるので基本的に`@ObservedObject var viewStore: ViewStoreOf<Feature>`を使用する
  * viewのextensionでも直接これを使用しvar宣言とする

* 日本語以外の言語設定での動作確認が必要

* [Missing required module 'FirebaseCore' in unit tests · Issue #10049 · firebase/firebase-ios-sdk](https://github.com/firebase/firebase-ios-sdk/issues/10049)
  * 恐らくXcode14の問題でBundle Loaderのパスに「/」が連続しており、testターゲットでビルドエラーになる。回避策としてBundle Loaderのパス定義を変更した。
