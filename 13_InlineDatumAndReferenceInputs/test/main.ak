use aiken/builtin.{Data, ByteArray}
use aiken/test
use cardano/transaction
use cardano_aiken/lesson13

fn output_with_datum(datum: Data) -> transaction::TxOutput {
  transaction::TxOutput { datum: Some(datum), ..transaction::TxOutput::default() }
}

fn reference_input_with_inline(datum: Data) -> transaction::Input {
  transaction::Input {
    output_reference: transaction::OutputReference::new(transaction::TxId(#[]), 0),
    resolved: output_with_datum(datum)
  }
}

fn context_with_refs(refs: List(transaction::Input)) -> transaction::ScriptContext {
  transaction::ScriptContext {
    purpose: transaction::ScriptPurpose::Spend(transaction::OutputReference::new(transaction::TxId(#[]), 0)),
    script_hash: #[],
    transaction: transaction::Transaction {
      reference_inputs: refs,
      ..transaction::Transaction::default()
    }
  }
}

test fn finds_owner_in_reference_inline_datum() {
  let owner = #"deadbeef"
  let refs = [reference_input_with_inline(Data::Bytes(owner))]
  let ctx = context_with_refs(refs)
  expect True = lesson13::main(Data::Bytes(#""), Data::Bytes(owner), ctx)
}

test fn owner_not_found_returns_false() {
  let refs = [reference_input_with_inline(Data::Bytes(#"abcd"))]
  let ctx = context_with_refs(refs)
  expect False = lesson13::main(Data::Bytes(#""), Data::Bytes(#"dead"), ctx)
}

test fn owner_can_be_in_list_datum() {
  let refs = [reference_input_with_inline(Data::List([Data::Bytes(#"alice"), Data::Bytes(#"bob")]))]
  let ctx = context_with_refs(refs)
  expect True = lesson13::main(Data::Bytes(#""), Data::Bytes(#"bob"), ctx)
}

test fn threshold_extracted_from_reference() {
  let refs = [reference_input_with_inline(Data::Integer(3))]
  let ctx = context_with_refs(refs)
  expect Some(3) = lesson13::threshold_from_reference(ctx)
}

test fn requires_min_reference_count() {
  let refs = [reference_input_with_inline(Data::Bytes(#"one"))]
  let ctx = context_with_refs(refs)
  expect False = lesson13::main(Data::Bytes(#""), Data::Integer(2), ctx)
  expect True = lesson13::main(Data::Bytes(#""), Data::Integer(1), ctx)
}

test fn owner_and_min_ada_list_branch() {
  let refs = [reference_input_with_inline(Data::Bytes(#"owner"))]
  let ctx = context_with_refs(refs)

  // 默认 lovelace 为 0，要求 1 时失败，要求 0 时通过
  expect False = lesson13::main(Data::Bytes(#""), Data::List([Data::Bytes(#"owner"), Data::Integer(1)]), ctx)
  expect True = lesson13::main(Data::Bytes(#""), Data::List([Data::Bytes(#"owner"), Data::Integer(0)]), ctx)
}

test fn fallback_passes_when_any_inline_exists() {
  let refs = [reference_input_with_inline(Data::Bytes(#"any"))]
  let ctx = context_with_refs(refs)
  expect True = lesson13::main(Data::Bytes(#""), Data::List([]), ctx)
}
