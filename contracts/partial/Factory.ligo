#include "./IFactory.ligo"

const createContr : createContrFunc =
[%Michelson(
  {|
    {
      UNPPAIIR;
      CREATE_CONTRACT
#if FA2_STANDARD_ENABLED
#include "../compiled/FA2.tz"
#else
#include "../compiled/FA12.tz"
#endif
      ;
      PAIR;
    }
  |} : createContrFunc
)];

function launchToken (const userParamss : userParams; var s : factoryStorage) : fullFactoryReturn is
block {
  const acc : account = record [
    balance = userParamss.totalSupply;
#if FA2_STANDARD_ENABLED
    allowances = (Set.empty : set(address));
#else
    allowances = (Map.empty : map(address, nat));
#endif
  ];

  const storage : storage = record [
    totalSupply = userParamss.totalSupply;
    ledger = (big_map [(Tezos.sender : address) -> (acc : account)] : big_map(address, account));
#if FA2_STANDARD_ENABLED
    token_metadata = userParamss.token_metadata;
    metadata = userParamss.metadata;
#endif
  ];
  const res : (operation * address) = createContr((None : option(key_hash)), 0mutez, storage);

  case (s.tokenList[Tezos.sender] : option(set(address))) of
  | None -> s.tokenList[Tezos.sender] := set [res.1]
  | Some(value) -> s.tokenList[Tezos.sender] := Set.add(res.1, value)
  end;
} with (list [res.0], s)

function main(const p : factoryAction; const s : factoryStorage) : fullFactoryReturn is
case p of
| LaunchToken(params) -> launchToken(params, s)
end;
