use aiken/builtin.{Data}

pub type State {
  Init
  Active
  Closed
}

pub type Action {
  Start
  Close
  Cancel
  ForceClose
}

pub fn transition(state: State, action: Action) -> State {
  when { state, action } is {
    {Init, Start} -> Active
    {Active, Close} -> Closed
    {Active, Cancel} -> Closed
    {Active, ForceClose} -> Closed
    _ -> state
  }
}

pub fn allow_transition(from: State, action: Action, to: State) -> Bool {
  transition(from, action) == to
}

/// Datum: 当前 State；Redeemer: Action；允许状态机只按合法路径前进。
pub fn main(datum: Data, redeemer: Data, _context: Data) -> Bool {
  when { datum, redeemer } is {
    {Data::Constr(0, []), Data::Constr(0, [])} -> allow_transition(Init, Start, Active)
    {Data::Constr(1, []), Data::Constr(1, [])} -> allow_transition(Active, Close, Closed)
    {Data::Constr(1, []), Data::Constr(2, [])} -> allow_transition(Active, Cancel, Closed)
    {Data::Constr(1, []), Data::Constr(3, [])} -> allow_transition(Active, ForceClose, Closed)
    _ -> False
  }
}
