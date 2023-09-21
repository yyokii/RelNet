## Dev memo

* FirestoreのドキュメントであるPersonやGroupなどのエンティティにプロパティ追加した場合、toDictionary()も更新すること

* 日本語以外の言語設定での動作確認

  * フリガナ欄の表示/非表示
  * 名前欄の順序
* [Missing required module 'FirebaseCore' in unit tests · Issue #10049 · firebase/firebase-ios-sdk](https://github.com/firebase/firebase-ios-sdk/issues/10049)
  * 恐らくXcode14の問題でBundle Loaderのパスに「/」が連続しており、testターゲットでビルドエラーになる。回避策としてBundle Loaderのパス定義を変更した。
