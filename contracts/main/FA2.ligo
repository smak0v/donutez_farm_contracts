#include "../partial/IFA2.ligo"

function get_account(const addr : address; const s : storage) : account is
block {
  var acc : account := record [
    balance = 0n;
    allowances = (set [] : set(address));
  ];

  case s.ledger[addr] of
  | None -> skip
  | Some(a) -> acc := a
  end;
} with acc

function iterate_transfer(const s : storage; const user_trx_params : transfer_param) : storage is
block {
  var sender_account : account := get_account(user_trx_params.from_, s);

  if user_trx_params.from_ = Tezos.sender or sender_account.allowances contains Tezos.sender then
    skip
  else
    failwith("FA2_NOT_OPERATOR");

  function make_transfer(const s : storage; const transfer : transfer_destination) : storage is
  block {
    sender_account := get_account(user_trx_params.from_, s);

    if default_token_id =/= transfer.token_id then
      failwith("FA2_TOKEN_UNDEFINED")
    else
      skip;

    if sender_account.balance < transfer.amount then
      failwith("FA2_INSUFFICIENT_BALANCE")
    else
      skip;

    sender_account.balance := abs(sender_account.balance - transfer.amount);
    s.ledger[user_trx_params.from_] := sender_account;

    var dest_account : account := get_account(transfer.to_, s);

    dest_account.balance := dest_account.balance + transfer.amount;
    s.ledger[transfer.to_] := dest_account;
  } with s;
} with (List.fold(make_transfer, user_trx_params.txs, s))

function iterate_update_operator(const s : storage; const params : update_operator_param) : storage is
block {
  case params of
  | Add_operator(param) -> block {
    if default_token_id =/= param.token_id then
      failwith("FA2_TOKEN_UNDEFINED")
    else
      skip;

    if Tezos.sender =/= param.owner then
      failwith("FA2_NOT_OWNER")
    else
      skip;

    var sender_account : account := get_account(param.owner, s);

    sender_account.allowances := Set.add(param.operator, sender_account.allowances);
    s.ledger[param.owner] := sender_account;
  }
  | Remove_operator(param) -> block {
    if default_token_id =/= param.token_id then
      failwith("FA2_TOKEN_UNDEFINED")
    else
      skip;

    if Tezos.sender =/= param.owner then
      failwith("FA2_NOT_OWNER")
    else
      skip;

    var sender_account : account := get_account(param.owner, s);

    sender_account.allowances := Set.remove(param.operator, sender_account.allowances);
    s.ledger[param.owner] := sender_account;
  }
  end;
} with s

function get_balance_of(const balance_params : balance_params; const s : storage) : list(operation) is
block {
  function look_up_balance(const l : list(balance_of_response); const request : balance_of_request) : list(balance_of_response) is
  block {
    if default_token_id =/= request.token_id then
      failwith("FA2_TOKEN_UNDEFINED")
    else
      skip;

    const sender_account : account = get_account(request.owner, s);
    const response : balance_of_response = record [
      request = request;
      balance = sender_account.balance;
    ];
  } with response # l;

  const accomulated_response : list(balance_of_response) = List.fold(look_up_balance, balance_params.requests, (nil: list(balance_of_response)));
} with list [transaction(accomulated_response, 0tz, balance_params.callback)]

function main(const action : token_action; var s : storage) : return is
block {
  skip;
} with case action of
  | Transfer(params) -> ((nil : list(operation)), List.fold(iterate_transfer, params, s))
  | Balance_of(params) -> (get_balance_of(params, s), s)
  | Update_operators(params) -> ((nil : list(operation)), List.fold(iterate_update_operator, params, s))
end;
