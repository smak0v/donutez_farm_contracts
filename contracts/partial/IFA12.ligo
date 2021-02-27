type trusted is address
type amt is nat

type account is record [
  balance : amt;
  allowances : map(trusted, amt);
]

type storage is record [
  totalSupply : amt;
  ledger : big_map(address, account);
]

type return is list(operation) * storage

const noOperations : list(operation) = nil;

type transferParams is michelson_pair(address, "from", michelson_pair(address, "to", amt, "value"), "")
type approveParams is michelson_pair(trusted, "spender", amt, "value")
type balanceParams is michelson_pair(address, "owner", contract(amt), "")
type allowanceParams is michelson_pair(michelson_pair(address, "owner", trusted, "spender"), "", contract(amt), "")
type totalSupplyParams is (unit * contract(amt))

type entryAction is
| Transfer of transferParams
| Approve of approveParams
| GetBalance of balanceParams
| GetAllowance of allowanceParams
| GetTotalSupply of totalSupplyParams
