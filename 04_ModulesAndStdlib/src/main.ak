use aiken/collection/list
use cardano_aiken/lesson04.helpers.{average}

/// 演示如何在 src/ 模块引用 lib/helpers 的函数。
pub fn describe_avg(values: list.List(Int)) -> String {
  when average(values) is {
    Some(avg) -> Int.to_string(avg)
    None -> "0"
  }
}
