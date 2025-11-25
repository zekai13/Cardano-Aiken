/// 最小化 spending validator：无条件返回 True。
validator hello_aiken {
  spend(_datum, _redeemer, _utxo, _tx) {
    True
  }
}
