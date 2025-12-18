use aiken/builtin.{Data}
use aiken/test
use cardano_aiken/lesson15

fn state_init() -> lesson15::State {
  lesson15::State::Init
}

fn state_active() -> lesson15::State {
  lesson15::State::Active
}

fn state_closed() -> lesson15::State {
  lesson15::State::Closed
}

fn action_start() -> lesson15::Action {
  lesson15::Action::Start
}

fn action_close() -> lesson15::Action {
  lesson15::Action::Close
}

fn action_cancel() -> lesson15::Action {
  lesson15::Action::Cancel
}

fn action_force_close() -> lesson15::Action {
  lesson15::Action::ForceClose
}

fn datum_of(state: lesson15::State) -> Data {
  when state is {
    lesson15::State::Init -> Data::Constr(0, [])
    lesson15::State::Active -> Data::Constr(1, [])
    lesson15::State::Closed -> Data::Constr(2, [])
  }
}

fn redeemer_of(action: lesson15::Action) -> Data {
  when action is {
    lesson15::Action::Start -> Data::Constr(0, [])
    lesson15::Action::Close -> Data::Constr(1, [])
    lesson15::Action::Cancel -> Data::Constr(2, [])
    lesson15::Action::ForceClose -> Data::Constr(3, [])
  }
}

test fn start_moves_to_active() {
  expect lesson15::State::Active = lesson15::transition(state_init(), action_start())
}

test fn close_moves_to_closed() {
  expect lesson15::State::Closed = lesson15::transition(state_active(), action_close())
}

test fn cancel_moves_to_closed() {
  expect lesson15::State::Closed = lesson15::transition(state_active(), action_cancel())
}

test fn force_close_moves_to_closed() {
  expect lesson15::State::Closed = lesson15::transition(state_active(), action_force_close())
}

test fn disallows_jump_from_init_to_closed() {
  expect False = lesson15::allow_transition(state_init(), action_close(), state_closed())
}

test fn validator_allows_valid_path() {
  let datum = datum_of(state_init())
  let redeemer = redeemer_of(action_start())
  expect True = lesson15::main(datum, redeemer, Data::Constr(0, []))
}

test fn validator_blocks_invalid_action() {
  let datum = datum_of(state_init())
  let redeemer = redeemer_of(action_close())
  expect False = lesson15::main(datum, redeemer, Data::Constr(0, []))
}

test fn validator_allows_force_close_from_active() {
  let datum = datum_of(state_active())
  let redeemer = redeemer_of(action_force_close())
  expect True = lesson15::main(datum, redeemer, Data::Constr(0, []))
}
