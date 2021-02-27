#if FA2_STANDARD_ENABLED
type tokenIdentifier is (address * nat)
#else
type tokenIdentifier is address
#endif

type factoryStorage is record [
  owner : address;
  admin : address;
  tokenList : big_map(address, set(address));
]

type account is record [
  balance : nat;
#if FA2_STANDARD_ENABLED
  allowances : set(address);
#else
  allowances : map(address, nat);
#endif
]

type token_metadata_info is record [
  token_id : nat;
  extras : map(string, bytes);
]

type storage is record [
  totalSupply : nat;
  ledger : big_map(address, account);
#if FA2_STANDARD_ENABLED
  token_metadata : big_map(nat, token_metadata_info);
  metadata : big_map(string, bytes);
#endif
]

type userParams is [@layout:comb] record [
  totalSupply : nat;
#if FA2_STANDARD_ENABLED
  token_metadata : big_map(nat, token_metadata_info);
  metadata : big_map(string, bytes);
#endif
]

type fullFactoryReturn is list(operation) * factoryStorage

type createContrFunc is (option(key_hash) * tez * storage) -> (operation * address)

type factoryAction is
| LaunchToken  of userParams
