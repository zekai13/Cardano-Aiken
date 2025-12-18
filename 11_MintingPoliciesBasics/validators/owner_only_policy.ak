use cardano_aiken/lesson11

validator owner_only_policy {
  mint(redeemer, policy_id, self) {
    lesson11.main(redeemer, policy_id, self)
  }
}
