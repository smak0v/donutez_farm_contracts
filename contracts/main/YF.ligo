#include "../partial/Types.ligo"

function getYFLPTokenTransferEntrypoint(const s : yfStorage) : contract(transfer_type) is
case (Tezos.get_entrypoint_opt("%transfer", s.yfParams.lpToken) : option(contract(transfer_type))) of
| Some(c) -> c
| None -> (failwith("getYFLPTokenTransferEntrypoint not found") : contract(transfer_type))
end;

function getYFRewardTokenTransferEntrypoint(const s : yfStorage) : contract(transfer_type) is
case (Tezos.get_entrypoint_opt("%transfer", s.yfParams.miningParams.rewardToken) : option(contract(transfer_type))) of
| Some(c) -> c
| None -> (failwith("getYFRewardTokenTransferEntrypoint not found") : contract(transfer_type))
end;

function getAccount(const user : address; const s : yfStorage) : yfAccount is
block {
  const acc : yfAccount = case s.ledger[user] of
    | Some(a) -> a
    | None -> record[
      staked = 0n;
      reward = 0n;
      lastRewardPerShare = 0n;
    ]
  end
} with acc

function updateRewards(var s : yfStorage) : yfStorage is
block {
  if s.lastUpdateTime < Tezos.now then block {
    if s.totalStaked > 0n then block {
      const deltaTimeInSeconds : nat = abs(Tezos.now - s.lastUpdateTime);
      const deltaTimeInPeriods : nat = deltaTimeInSeconds / s.yfParams.miningParams.periodInSeconds;
      const newRewards : nat = deltaTimeInPeriods * s.yfParams.miningParams.rewardPerPeriod;

      s.rewardPerShare := s.rewardPerShare + newRewards / s.totalStaked;
    }
    else
      skip;

    s.lastUpdateTime := Tezos.now;
  }
  else
    skip;
} with s

function stake_(const addr : address; const this : address; const value : nat; const s : yfStorage) : yfReturn is
block {
  s := updateRewards(s);

  var operations := noOperations;
  var acc : yfAccount := getAccount(addr, s);

  acc.reward := acc.reward + (acc.staked * abs(s.rewardPerShare - acc.lastRewardPerShare));
  acc.staked := acc.staked + value;

  s.ledger[addr] := acc;
  s.totalStaked := s.totalStaked + value;

  operations := Tezos.transaction(
    TransferType(addr, (this, value)),
    0mutez,
    getYFLPTokenTransferEntrypoint(s)
  ) # operations;
} with (operations, s)

function stake(const value : nat; var s : yfStorage) : yfReturn is
block {
  skip;
} with stake_(Tezos.sender, Tezos.self_address, value, s)

function stakeFor(const addr : address; const value : nat; const s : yfStorage) : yfReturn is
block {
  skip;
} with stake_(addr, Tezos.self_address, value, s)

function unstake(var value : nat; var s : yfStorage) : yfReturn is
block {
  s := updateRewards(s);

  var operations := noOperations;
  var acc : yfAccount := getAccount(Tezos.sender, s);

  acc.reward := acc.reward + (acc.staked * abs(s.rewardPerShare - acc.lastRewardPerShare));

  if value = 0n then
    value := acc.staked // unstake all LP tokens
  else
    skip;

  if value <= acc.staked then
    skip
  else
    failwith("Staked balance too low");

  acc.staked := abs(acc.staked - value);

  s.ledger[Tezos.sender] := acc;
  s.totalStaked := abs(s.totalStaked - value);

  operations := Tezos.transaction(
    TransferType(Tezos.self_address, (Tezos.sender, value)),
    0mutez,
    getYFLPTokenTransferEntrypoint(s)
  ) # operations;
} with (operations, s)

function claim(var s : yfStorage) : yfReturn is
block {
  s := updateRewards(s);

  var operations := noOperations;
  var acc : yfAccount := getAccount(Tezos.sender, s);

  acc.reward := acc.reward + (acc.staked * abs(s.rewardPerShare - acc.lastRewardPerShare));

  const value : nat = acc.reward;

  if value = 0n then
    skip
  else block {
    acc.reward := 0n;

    operations := Tezos.transaction(
      TransferType(Tezos.self_address, (Tezos.sender, value)),
      0mutez,
      getYFRewardTokenTransferEntrypoint(s)
    ) # operations;
  };

  s.ledger[Tezos.sender] := acc;
} with (operations, s)

function main(const action : yfActions; const s : yfStorage) : yfReturn is
case action of
| Stake(v) -> stake(v, s)
| StakeFor(v) -> stakeFor(v.0, v.1, s)
| Unstake(v) -> unstake(v, s)
| Claim(v) -> claim(s)
end
