pub type CounterDatum {
  CounterDatum(version: Int, value: Int)
}

pub type CounterRedeemer {
  Increment
  Reset
}

pub fn apply(datum: CounterDatum, redeemer: CounterRedeemer) -> CounterDatum {
  when redeemer is {
    Increment -> CounterDatum(datum.version, datum.value + 1)
    Reset -> CounterDatum(datum.version + 1, 0)
  }
}
