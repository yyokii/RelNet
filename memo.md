* Scopeとは

* / と \ について

* Navigation周り

* stack point

  * ```swift
    .ifLet(\.$destination, action: /Action.destination) {
                Destination()
            }
    ```

    これのつけ忘れで、

    `To fix this, invoke "BindingReducer()" from your feature reducer's "body".` が発生しバインディングがうまくいかず、どこ直せばいいか分からずスタックした。