// Common types
type mining_params is [@layout:comb] record [
  rewardToken: address;
  lifetime: nat;          // In seconds
  periodInSeconds: nat;   // How often rewards will be distributed
  rewardPerPeriod: nat;
]

type deploy_yf_params is [@layout:comb] record [
  lpToken: address;
  miningParams: mining_params;
]

type transfer_params is michelson_pair(address, "from", michelson_pair(address, "to", nat, "value"), "")
type transfer_type is TransferType of transfer_params

type get_balance_params is michelson_pair(address, "owner", contract(nat), "")
type get_balance_type is GetBalanceType of get_balance_params

[@inline] const noOperations : list(operation) = nil;


// Yield Farmin Constructor types
type deploy_fee_params is [@layout:comb] record [
  deployFee: nat;
  deployAndStakeFee: nat;
  minStakeAmount: nat;
]

type deploy_and_stake_params is [@layout:comb] record [
  deployAndStake: bool;
  amountForStake: nat;
]

type deploy_yf_params_type is deploy_yf_params * deploy_and_stake_params

type yfConstructorActions is
| SetDeployFee of deploy_fee_params
| SetDTZTokenAddress of address
| SetDTZYFAddress of address
| DeployYF of deploy_yf_params_type
| WithdrawDTZTokens of unit
| WithdrawDTZTokensCallback of nat

type yfConstructorStorage is [@layout:comb] record [
  admin: address;
  dtzToken: address;
  dtzYF: address;
  deployFee: deploy_fee_params;
  yieldFarmings: map(address, set(address));
]

type yfConstructorReturn is list(operation) * yfConstructorStorage


// Yield Farming types
type yfAccount is [@layout:comb] record [
  staked: nat;
  reward: nat;
  lastRewardPerShare: nat;
]

type yfStorage is [@layout:comb] record [
  totalStaked: nat;
  rewardPerShare: nat;
  lastUpdateTime: timestamp;
  ledger: big_map(address, yfAccount);
  yfParams: deploy_yf_params;
]

type yfReturn is list(operation) * yfStorage

type yfActions is
| Stake of nat
| StakeFor of address * nat
| Unstake of nat
| Claim of unit

type stake_for_type is StakeForType of address * nat

type deployYFContractFunction is (option(key_hash) * tez * yfStorage) -> (operation * address)
