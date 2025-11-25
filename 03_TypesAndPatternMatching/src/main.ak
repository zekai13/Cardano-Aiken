pub type OrderStatus {
  Draft
  Active { buyer: String, price: Int }
  Cancelled(String)
}

pub fn label(status: OrderStatus) -> String {
  when status is {
    Draft -> "Waiting"
    Active { buyer, price } -> buyer <> " offers " <> Int.to_string(price)
    Cancelled(reason) -> "Cancelled: " <> reason
  }
}

pub fn next(next_action: String, current: OrderStatus) -> OrderStatus {
  when { next_action, current } is {
    {"activate", Draft} -> Active { buyer: "TODO", price: 0 }
    {"cancel", _} -> Cancelled("manual")
    _ -> current
  }
}
