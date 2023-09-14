
* AsyncThrowingStreamを利用したclientを利用するviewのpreview方法

* Standupsにおいて、AppFeatureでdestinationの設定しているのはなんで？子viewでlink設定するのではだめ？

  * navigation周りよくわからない
  * Navigation
    * tree-based navigation
    * stack-based navigation
      * NavigationStack

* https://zenn.dev/yimajo/articles/da23e10ee9cf74

  * > ちなみにProfile画面でresetする際に元データをリセットしてるのはsend(アクション)時にプロパティのsetが動くから。Reducerの関数が動作するとStateが書き換わるのを利用してそう。

  * action → reducer → state更新 → stateのsetterが動作 てこと？

* view間での通知/共有方法

  * delegate
  * 共有Stateを作成

* sheet表示の時の引数、雰囲気で渡している

* 依存する~client作成する際に、プロパティを**@Sendable**にしているのはなんで？

  * データ競合を起こす処理が発生する可能性がありそれをケアするため
  * https://qiita.com/takehilo/items/39a3d4b14f7e1555e8c9
  * https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/swiftconcurrency/

* `.run`

  * ````
    effectの中で、何度でもアクションを発することができる非同期の作業単位をラップする。
    
    例えば、依存関係として保持するクライアントに非同期ストリームがあったとします：
    
    ```swift
    struct EventsClient {
      var events: () -> AsyncStream<Event>
    }
    ```
    
    `for await` を使って `run` effectに設定し、ストリームの各アクションをシステムに送り返すことができる：
    
    ```swift
    case .startButtonTapped:
      return .run { send in
        for await event in self.events() {
          send(.event(event))
        }
      }
    ```
    
    run` のクロージャに渡される `send` 引数の使い方については ``Send`` を参照してください。
    
    `run(priority:operation:catch:fileID:line:)`に渡されたクロージャは、エラーを投げることができます。
    しかし、non-cancellationなエラーがスローされた場合、シミュレータやデバイス上で実行すると実行時警告が表示され、テストではテスト失敗の原因になります。non-cancellation以外のエラーをキャッチするには、末尾に `catch` をつけます。
    ````

  * CancellationError

    * https://developer.apple.com/documentation/swift/cancellationerror?changes=_3

* Dependencied

  * https://zenn.dev/kalupas226/articles/25ec066246473e

* BindingViewStore

* @PresentationState

  * 

* たまに出てくるiflet何？

  * 親Reducerの結合時に使うものみたい。
  * optionalなStateに対して、それがnon nilの時に動作するReducerを結合する際に使用

* return .none しないケースなにがあるっけ？

* Scopeとは

  * https://github.com/pointfreeco/swift-composable-architecture/blob/main/Examples/CaseStudies/SwiftUICaseStudies/01-GettingStarted-Composition-TwoCounters.swift
    * この画面では、reducer builder と `Scope` reducer、そしてstoreの `scope` 演算子を使用して、小さなfeatureをより大きなfeatureに合成する方法を示します。
    * 

* / と \ について

* Navigation周り

  * NavigationStackStoreを利用している時、子viewが遷移する時に親のpath.stateをstateに指定するんだ？これはstack管理のため？
  * sampleのstandup においてAppFeatureにおいてNavigationStackを利用しているが、AppFeatureのようなRootでTabView使いたいときってnavigationのdestinationどうすればいいのだろうか。愚直にAppFeatureでNavigationStackなものをTabで表示し遷移すると別タブでもその状態が再現される
    * AppFeatureで管理しなければいい話ではあるが、それでいいのか