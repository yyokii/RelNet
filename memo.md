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

* stack point

  * ```swift
    .ifLet(\.$destination, action: /Action.destination) {
                Destination()
            }
    ```

    これのつけ忘れで、

    `To fix this, invoke "BindingReducer()" from your feature reducer's "body".` が発生しバインディングがうまくいかず、どこ直せばいいか分からずスタックした。