export const faucetIDL = ({ IDL }) => {
    const Subaccount = IDL.Vec(IDL.Nat8);
    const Account = IDL.Record({
      'owner' : IDL.Principal,
      'subaccount' : IDL.Opt(Subaccount),
    });
    const BalanceOfResponse = IDL.Record({
      'msg' : IDL.Text,
      'timeStamp' : IDL.Int,
      'totalSupply' : IDL.Nat,
      'accountBalance' : IDL.Nat,
      'responseStatus' : IDL.Text,
    });
    const TotalSupplyResponse = IDL.Record({
      'msg' : IDL.Text,
      'timeStamp' : IDL.Int,
      'totalSupply' : IDL.Nat,
      'responseStatus' : IDL.Text,
    });
    const Balance = IDL.Nat;
    const Mint = IDL.Record({
      'to' : Account,
      'memo' : IDL.Opt(IDL.Vec(IDL.Nat8)),
      'created_at_time' : IDL.Opt(IDL.Nat64),
      'amount' : Balance,
    });
    const TxIndex = IDL.Nat;
    const Timestamp = IDL.Nat64;
    const TransferError = IDL.Variant({
      'GenericError' : IDL.Record({
        'message' : IDL.Text,
        'error_code' : IDL.Nat,
      }),
      'TemporarilyUnavailable' : IDL.Null,
      'BadBurn' : IDL.Record({ 'min_burn_amount' : Balance }),
      'Duplicate' : IDL.Record({ 'duplicate_of' : TxIndex }),
      'BadFee' : IDL.Record({ 'expected_fee' : Balance }),
      'CreatedInFuture' : IDL.Record({ 'ledger_time' : Timestamp }),
      'TooOld' : IDL.Null,
      'InsufficientFunds' : IDL.Record({ 'balance' : Balance }),
    });
    const Result = IDL.Variant({ 'ok' : Balance, 'err' : TransferError });
    const MintNowResponse = IDL.Record({
      'msg' : IDL.Text,
      'timeStamp' : IDL.Int,
      'responseStatus' : IDL.Text,
      'mintResponse' : Result,
    });
    return IDL.Service({
      'checkAccountBalance' : IDL.Func([Account], [BalanceOfResponse], []),
      'getTotalSupply' : IDL.Func([], [TotalSupplyResponse], []),
      'mintNow' : IDL.Func([Mint], [MintNowResponse], []),
    });
  };
  export const init = ({ IDL }) => { return []; };