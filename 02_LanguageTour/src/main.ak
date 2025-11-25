use aiken/collection/list

pub type Message {
  Hello(String)
  Ping
  Numbered(Int)
  Goodbye(String)
}

pub fn greet(name: String) -> String {
  "Hello, " <> name
}

pub fn greet_with_default(name: Option(String)) -> String {
  when name is {
    Some(value) -> greet(value)
    None -> "Hello, Anonymous"
  }
}

pub fn clamp(value: Int, min: Int, max: Int) -> Int {
  if value < min {
    min
  } else if value > max {
    max
  } else {
    value
  }
}

pub fn describe(msg: Message) -> String {
  when msg is {
    Hello(name) -> "Hello, " <> name
    Goodbye(name) -> "Bye, " <> name
    Ping -> "PONG"
    Numbered(value) -> "Number: " <> Int.to_string(value)
  }
}

pub fn classify(value: Int) -> String {
  when value is {
    v if v < 0 -> "negative"
    0 -> "zero"
    _ -> "positive"
  }
}

pub fn average(values: List(Int)) -> Option(Int) {
  let count = list.length(values)
  let total = list.fold(values, 0, fn(acc, v) { acc + v })

  if count == 0 {
    None
  } else {
    Some(total / count)
  }
}

pub fn sum_positive(values: List(Int)) -> Int {
  list.fold(values, 0, fn(acc, value) {
    if value > 0 {
      acc + value
    } else {
      acc
    }
  })
}
