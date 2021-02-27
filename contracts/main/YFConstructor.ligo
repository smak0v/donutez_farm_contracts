#include "../partial/Types.ligo"

const deployContract : deployYFContractFunction =
[%Michelson(
  {|
    {
      UNPPAIIR;
      CREATE_CONTRACT
#include "../compiled/YF.tz"
      ;
      PAIR;
    }
  |} : deployYFContractFunction
)];

function getDTZTokenTransferEntrypoint(const s : yfConstructorStorage) : contract(transfer_type) is
case (Tezos.get_entrypoint_opt("%transfer", s.dtzToken) : option(contract(transfer_type))) of
| Some(c) -> c
| None -> (failwith("getDTZTokenTransferEntrypoint not found") : contract(transfer_type))
end;

function getDTZYFStakeForEntrypoint(const s : yfConstructorStorage) : contract(stake_for_type) is
case (Tezos.get_entrypoint_opt("%stakeFor", s.dtzYF) : option(contract(stake_for_type))) of
| Some(c) -> c
| None -> (failwith("getDTZYFStakeForEntrypoint not found") : contract(stake_for_type))
end;

function setDeployFee(const deployFeeParams : deploy_fee_params; var s : yfConstructorStorage) : yfConstructorReturn is
block {
  if Tezos.sender =/= s.admin then failwith("Allowed only for admin") else skip;

  s.deployFee.deployFee := deployFeeParams.deployFee;
  s.deployFee.deployAndStakeFee := deployFeeParams.deployAndStakeFee;
  s.deployFee.minStakeAmount := deployFeeParams.minStakeAmount;
} with (noOperations, s)

function setDTZTokenAddress(const dtzToken : address; var s : yfConstructorStorage) : yfConstructorReturn is
block {
  if Tezos.sender =/= s.admin then failwith("Allowed only for admin") else skip;

  s.dtzToken := dtzToken;
} with (noOperations, s)

function setDTZYFAddress(const dtzYF : address; var s : yfConstructorStorage) : yfConstructorReturn is
block {
  if Tezos.sender =/= s.admin then failwith("Allowed only for admin") else skip;

  s.dtzYF := dtzYF;
} with (noOperations, s)

function deployYF(const deployParams : deploy_yf_params; const deployAndStakeParams : deploy_and_stake_params; var s : yfConstructorStorage) : yfConstructorReturn is
block {
  var operations := noOperations;

  if deployAndStakeParams.deployAndStake then block {
    if deployAndStakeParams.amountForStake < s.deployFee.minStakeAmount then
      failwith("Not enough tokens to stake")
    else
      skip;

    operations := Tezos.transaction(
      TransferType(Tezos.sender, (Tezos.self_address, s.deployFee.deployAndStakeFee)),
      0mutez,
      getDTZTokenTransferEntrypoint(s)
    ) # operations;

    operations := Tezos.transaction(
      StakeForType(Tezos.sender, deployAndStakeParams.amountForStake),
      0mutez,
      getDTZYFStakeForEntrypoint(s)
    ) # operations;
  }
  else block {
    operations := Tezos.transaction(
      TransferType(Tezos.sender, (Tezos.self_address, s.deployFee.deployFee)),
      0mutez,
      getDTZTokenTransferEntrypoint(s)
    ) # operations;
  };

  const yfInitialStorage : yfStorage = record[
    totalStaked = 0n;
    rewardPerShare = 0n;
    lastUpdateTime = Tezos.now;
    ledger = (big_map [] : big_map(address, yfAccount));
    yfParams = deployParams;
  ];
  const result : (operation * address) = deployContract((None : option(key_hash)), 0mutez, yfInitialStorage);

  case (s.yieldFarmings[Tezos.sender] : option(set(address))) of
  | None -> s.yieldFarmings[Tezos.sender] := set [result.1]
  | Some(v) -> s.yieldFarmings[Tezos.sender] := Set.add(result.1, v)
  end;

  operations := result.0 # operations;
} with (operations, s)

function withdrawDTZTokens(const s : yfConstructorStorage) : yfConstructorReturn is
block {
  if Tezos.sender =/= s.admin then failwith("Allowed only for admin") else skip;

  var dtzToken : contract(get_balance_type) := nil;

  case (Tezos.get_entrypoint_opt("%getBalance", s.dtzToken) : option(contract(get_balance_type))) of
  | None -> failwith("DTZ token not found")
  | Some(c) -> dtzToken := c
  end;

  var params : get_balance_type := nil;

  case (Tezos.get_entrypoint_opt("%withdrawDTZTokensCallback", Tezos.self_address) : option(contract(nat))) of
  | None -> failwith("Callback function not found")
  | Some(p) -> params := GetBalanceType(s.dtzToken, p)
  end;
} with (list [Tezos.transaction(params, 0mutez, dtzToken)], s)

function withdrawDTZTokensCallback(const dtz_amount : nat; const s : yfConstructorStorage) : yfConstructorReturn is
block {
  const operations = list [Tezos.transaction(
    TransferType(Tezos.self_address, (s.admin, dtz_amount)),
    0mutez,
    getDTZTokenTransferEntrypoint(s)
  )];
} with (operations, s)

function main(const action : yfConstructorActions; const s : yfConstructorStorage) : yfConstructorReturn is
case action of
| SetDeployFee(v) -> setDeployFee(v, s)
| SetDTZTokenAddress(v) -> setDTZTokenAddress(v, s)
| SetDTZYFAddress(v) -> setDTZYFAddress(v, s)
| DeployYF(v) -> deployYF(v.0, v.1, s)
| WithdrawDTZTokens(v) -> withdrawDTZTokens(s)
| WithdrawDTZTokensCallback(v) -> withdrawDTZTokensCallback(v, s)
end
