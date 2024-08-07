use aiken/builtin
use aiken/bytearray
use aiken/list
use aiken/transaction.{
  InlineDatum, Output, OutputReference, ScriptContext, Spend, Transaction,
}
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{Value, ada_asset_name, ada_policy_id, from_asset}
use simplemarketplace_types_ryan.{VerificationKeyHash}

pub fn buy_function(
  ctx: ScriptContext,
  price_asset: Int,
  seller_addr: Address,
) -> Bool {
  let ScriptContext { transaction, purpose } = ctx
  let Transaction { outputs, .. } = transaction

  expect Spend(out_ref) = purpose
  let val: Value = from_asset(ada_policy_id, ada_asset_name, price_asset)

  expect [_] =
    list.filter(
      outputs,
      fn(output) {
        output.value == val && output.address == seller_addr && datum_tagging_hash(
          output,
          out_ref,
        )
      },
    )
  True
}

pub fn datum_tagging_hash(output: Output, out_ref: OutputReference) -> Bool {
  let datum_tag =
    out_ref
      |> builtin.serialise_data
      |> builtin.blake2b_256
      |> InlineDatum

  output.datum == datum_tag
}

pub fn must_be_signed_by(
  transaction: Transaction,
  vk: VerificationKeyHash,
) -> Bool {
  list.has(transaction.extra_signatories, vk)
}

pub fn create_address(
  pkh: VerificationKeyHash,
  sc: VerificationKeyHash,
) -> Address {
  // empty bytearrays means dont add the sc to the pkh
  if bytearray.is_empty(sc) {
    credential.from_verification_key(pkh)
  } else {
    credential.from_verification_key(pkh)
      |> credential.with_delegation_key(sc)
  }
}
// //looking to make sure the value from the transaction is in the list of outputs
// pub fn check_if_paid(
//   outputs: List<Output>,
//   price_asset: Int,
//   addr: Address,
// ) -> Bool {
//   //constructing value to look for in outputs
//   let val: Value = from_asset(ada_policy_id, ada_asset_name, price_asset)
//   let filteredlist =
//     list.filter(
//       outputs,
//       fn(output) { output.value == val && output.address == addr },
//     )
//   list.length(filteredlist) == 1
// }

// pub fn own_input_own_output(
//   inputs: List<Input>,
//   outputs: List<Output>,
//   out_ref: OutputReference,
// ) -> Bool {
//   let input: Input = find_own_input(inputs, out_ref)
//   let outputs: List<Output> = output_by_value(outputs, input.output.value)
//   //find_own_outputs(outputs, out_ref)
//   list.any(
//     outputs,
//     fn(output) {
//       output.address == input.output.address && datum_tagging_hash(
//         output,
//         out_ref,
//       )
//     },
//   )
// }

// // Get input from the script.
// fn find_own_input(inputs: List<Input>, out_ref: OutputReference) -> Input {
//   //expect and input from the out_ref.
//   expect Some(input) =
//     inputs
//       |> transaction.find_input(out_ref)

//   input
// }

// // Get outputs to the script.
// fn find_own_outputs(
//   outputs: List<Output>,
//   out_ref: OutputReference,
// ) -> List<Output> {
//   //find the output based on the hash of the transaciton id hash
//   let own_outputs = outputs |> transaction.find_script_outputs(out_ref.transaction_id.hash)
//   own_outputs
// }

// pub fn output_by_value(outputs: List<Output>, value: Value) -> List<Output> {
//   list.filter(outputs, fn(output) { output.value == value })
// }
