// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.alloc import alloc
from openzeppelin.security.safemath.library import SafeUint256

@contract_interface
namespace IBondNFT {
    func safeMint(to: felt, tokenId: Uint256, data_len: felt, data: felt*, tokenURI: felt) {
    }

    func transferFrom(from_: felt, to: felt, tokenId: Uint256) {
    }
}

@contract_interface
namespace IBLUSD {
    func mint(to: felt, amount: Uint256) {
    }

    func totalSupply() -> (totalSupply: Uint256) {
    }

    func transfer_from(sender: felt, recipient: felt, amount: Uint256) -> (success: felt) {
    }
    func transfer(recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func balanceOf(account: felt) -> (balance: Uint256) {
    }
}

@contract_interface
namespace ILUSD {
    func transfer_from(sender: felt, recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func transfer(recipient: felt, amount: Uint256) -> (success: felt) {
    }
    func balanceOf(account: felt) -> (balance: Uint256) {
    }
}

@contract_interface
namespace ICurvePool {
    func add_liquidity(_LUSD3CRVAmount: Uint256) {
    }

    func remove_liquidity(_LUSD3CRVAmount: Uint256) {
    }

    func calcLUSDToLUSD3CRV(_LUSD3CRVAmount: Uint256) {
    }

    func calcLUSD3CRVToLUSD(_LUSD3CRVAmount: Uint256) {
    }
}

@contract_interface
namespace IMockYearnVault {
    func deposit(_tokenAmount: Uint256) {
    }

    func withdraw(_tokenAmount: Uint256) {
    }

    func calcTokenToYToken(_tokenAmount: Uint256) {
    }

    func calcYTokenToToken(_yTokenAmount: Uint256) -> (success: Uint256) {
    }

    func balanceOf(account: felt) -> (balance: Uint256) {
    }
}

@storage_var
func lusd_address_() -> (value: felt) {
}

@storage_var
func blusd_address_() -> (value: felt) {
}

@storage_var
func bond_address_() -> (value: felt) {
}
@storage_var
func mock_yearn_lusd_vault_address_() -> (value: felt) {
}
@storage_var
func mock_yearn_curve_vault_address_() -> (value: felt) {
}

@storage_var
func mock_curve_pool_address_() -> (value: felt) {
}

struct BondData {
    lusd_amount: Uint256,
    start_time: felt,
}

@storage_var
func id_to_bond_data_(id: Uint256) -> (data: BondData) {
}

@storage_var
func total_pending_LUSD_() -> (value: Uint256) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _bond_address: felt,
    _lusd_address: felt,
    _blusd_address: felt,
    _mock_curve_pool_address: felt,
    _mock_yearn_lusd_vault_address: felt,
    _mock_yearn_curve_vault_address: felt,
) {
    bond_address_.write(_bond_address);
    lusd_address_.write(_lusd_address);
    blusd_address_.write(_blusd_address);
    mock_curve_pool_address_.write(_mock_curve_pool_address);
    mock_yearn_lusd_vault_address_.write(_mock_yearn_lusd_vault_address);
    mock_yearn_curve_vault_address_.write(_mock_yearn_curve_vault_address);

    return ();
}

@external
func create_bond{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    lusd_amount: Uint256
) {
    alloc_locals;
    let (caller_address) = get_caller_address();

    let token_id = Uint256(1, 0);
    let len = 3;

    let (data_ptr) = alloc();
    assert [data_ptr] = 9;
    assert [data_ptr + 1] = 16;
    assert [data_ptr + 2] = 25;

    let (bond_address) = bond_address_.read();
    IBondNFT.safeMint(
        contract_address=bond_address,
        to=caller_address,
        tokenId=token_id,
        data_len=len,
        data=data_ptr,
        tokenURI=len,
    );

    let (timestamp) = get_block_timestamp();
    let bond_data = BondData(lusd_amount=lusd_amount, start_time=timestamp);
    id_to_bond_data_.write(token_id, bond_data);

    let (total_pending) = total_pending_LUSD_.read();
    let (new_amount: Uint256) = SafeUint256.add(total_pending, lusd_amount);
    total_pending_LUSD_.write(new_amount);

    let (this_contract_address) = get_contract_address();
    let (lusd_address) = lusd_address_.read();
    ILUSD.transfer_from(
        contract_address=lusd_address,
        sender=caller_address,
        recipient=this_contract_address,
        amount=lusd_amount,
    );

    let (yearn_lusd_vault_address) = mock_yearn_lusd_vault_address_.read();
    IMockYearnVault.deposit(contract_address=yearn_lusd_vault_address, _tokenAmount=lusd_amount);
    return ();
}

// https://github.com/liquity/ChickenBond/blob/f51be4cec25f941a030ccc68d4bf2b66d1340674/LUSDChickenBonds/src/ChickenBondManager.sol
// @external
func chicken_out{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _bond_id: Uint256
) {
    // requires caller be bond owner
    alloc_locals;

    // _requireCallerOwnsBond(_bondID);

    // uint bondedLUSD = idToBondData[_bondID].lusdAmount;
    let (data: BondData) = id_to_bond_data_.read(id=_bond_id);
    // totalPendingLUSD -= bondedLUSD;
    let (total_pending) = total_pending_LUSD_.read();
    let (new_total: Uint256) = SafeUint256.sub_le(total_pending, data.lusd_amount);
    total_pending_LUSD_.write(new_total);

    // delete idToBondData[_bondID];

    let (yearn_lusd_vault_address) = mock_yearn_lusd_vault_address_.read();

    // uint yTokensToBurn = yearnLUSDVault.calcYTokenToToken(bondedLUSD);
    let (y_tokens_to_burn: Uint256) = IMockYearnVault.calcYTokenToToken(
        contract_address=yearn_lusd_vault_address, _yTokenAmount=data.lusd_amount
    );

    // yearnLUSDVault.withdraw(yTokensToBurn);
    IMockYearnVault.withdraw(
        contract_address=yearn_lusd_vault_address, _tokenAmount=y_tokens_to_burn
    );

    // Send bonded LUSD back to caller and burn their bond NFT
    // lusdToken.transfer(msg.sender, bondedLUSD);

    let (caller_address) = get_caller_address();
    let (this_contract_address) = get_contract_address();
    let (lusd_address) = lusd_address_.read();

    ILUSD.transfer_from(
        contract_address=lusd_address,
        sender=this_contract_address,
        recipient=caller_address,
        amount=data.lusd_amount,
    );
    // bondNFT.burn(_bondID);
    let (bond_address) = bond_address_.read();
    IBondNFT.transferFrom(
        contract_address=bond_address, from_=caller_address, to=0, tokenId=_bond_id
    );

    return ();
}

@external
func chicken_in{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _bond_id: Uint256
) {
    alloc_locals;

    // _requireCallerOwnsBond(_bondID);

    // BondData memory bond = idToBondData[_bondID];
    let (data: BondData) = id_to_bond_data_.read(id=_bond_id);
    // uint accruedLUSD = _calcAccruedSLUSD(bond);
    let (accrued_LUSD) = _calc_accrued_SLUD(data);

    // _requireCapGreaterThanAccruedSLUSD(accruedLUSD, bond.lusdAmount);
    // TODO DO THIS REQUIRE

    // delete idToBondData[_bondID];
    // totalPendingLUSD -= bond.lusdAmount;
    let (total_pending) = total_pending_LUSD_.read();
    let (total: Uint256) = SafeUint256.sub_le(total_pending, data.lusd_amount);
    total_pending_LUSD_.write(total);

    // sLUSDToken.mint(msg.sender, accruedLUSD);
    let (blusd_address) = blusd_address_.read();
    let (caller_address) = get_caller_address();

    IBLUSD.mint(contract_address=blusd_address, to=caller_address, amount=accrued_LUSD);

    // bondNFT.burn(_bondID);
    let (bond_address) = bond_address_.read();

    IBondNFT.transferFrom(
        contract_address=bond_address, from_=caller_address, to=0, tokenId=_bond_id
    );

    return ();
}

func redeem{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _sLUSD_to_redeem: Uint256
) {
    alloc_locals;
    // uint fractionOfSLUSDToRedeem = _sLUSDToRedeem * 1e18 / sLUSDToken.totalSupply();
    //

    let (blusd_address) = blusd_address_.read();
    let (total_supply: Uint256) = IBLUSD.totalSupply(contract_address=blusd_address);

    let decimals = Uint256(1 * 10 ** 18, 0);

    let (total_units: Uint256) = SafeUint256.mul(_sLUSD_to_redeem, decimals);
    let (fractionOfSLUSDToRedeem: Uint256, o: Uint256) = SafeUint256.div_rem(
        total_units, total_supply
    );

    // // Calculate redemption fraction to withdraw, given that we leave the fee inside the system
    // uint fractionOfAcquiredLUSDToWithdraw = fractionOfSLUSDToRedeem * (1e18 - calcRedemptionFeePercentage()) / 1e18;

    let (redemption_fee: Uint256) = calcRedemptionFeePercentage();
    let (normalized_percentage: Uint256) = SafeUint256.sub_le(decimals, redemption_fee);
    let (acquired_LUSD: Uint256) = SafeUint256.mul(fractionOfSLUSDToRedeem, normalized_percentage);
    let (fraction_of_acquired_LUSD_to_withdraw: Uint256, o: Uint256) = SafeUint256.div_rem(
        normalized_percentage, decimals
    );

    // uint yTokensToWithdrawFromLUSDVault = yearnLUSDVault.balanceOf(address(this)) * fractionOfAcquiredLUSDToWithdraw / 1e18;
    let (this_address) = get_contract_address();
    let (yearn_lusd_vault_address) = mock_yearn_lusd_vault_address_.read();
    let (this_address_balance: Uint256) = IMockYearnVault.balanceOf(
        contract_address=yearn_lusd_vault_address, account=this_address
    );
    let (fraction: Uint256) = SafeUint256.mul(
        fractionOfSLUSDToRedeem, fraction_of_acquired_LUSD_to_withdraw
    );
    let (y_tokens_to_withdraw_from_LUSD_vault: Uint256, o: Uint256) = SafeUint256.div_rem(
        fraction, decimals
    );

    // // The LUSD and LUSD3CRV deltas from SP/Curve withdrawals are the amounts to send to the redeemer
    // uint lusdBalanceBefore = lusdToken.balanceOf(address(this));

    let (lusd_address) = lusd_address_.read();
    let (lusd_balance_before: Uint256) = ILUSD.balanceOf(
        contract_address=lusd_address, account=this_address
    );

    // yearnLUSDVault.withdraw(yTokensToWithdrawFromLUSDVault); // obtain LUSD from Yearn
    IMockYearnVault.withdraw(
        contract_address=yearn_lusd_vault_address, _tokenAmount=y_tokens_to_withdraw_from_LUSD_vault
    );

    // uint lusdBalanceDelta = lusdToken.balanceOf(address(this)) - lusdBalanceBefore;

    let (lusd_balance_now: Uint256) = ILUSD.balanceOf(
        contract_address=lusd_address, account=this_address
    );

    let (lusd_balance_delta: Uint256) = SafeUint256.sub_le(lusd_balance_now, lusd_balance_before);

    // // Burn the redeemed sLUSD
    // sLUSDToken.burn(msg.sender, _sLUSDToRedeem);

    let (caller_address) = get_caller_address();
    let (blusd_address) = blusd_address_.read();
    IBLUSD.transfer_from(
        contract_address=blusd_address, sender=caller_address, recipient=0, amount=_sLUSD_to_redeem
    );

    // // Send the LUSD to the redeemer
    // lusdToken.transfer(msg.sender, lusdBalanceDelta);

    ILUSD.transfer(
        contract_address=lusd_address, recipient=caller_address, amount=lusd_balance_delta
    );

    return ();
}

func calc_accrued_SLUD{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _bond_id: Uint256
) -> (res: Uint256) {
    let (data: BondData) = id_to_bond_data_.read(id=_bond_id);
    let (res: Uint256) = _calc_accrued_SLUD(data);
    return (res=res);
}

func _calc_accrued_SLUD{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    bond: BondData
) -> (res: Uint256) {
    // if (bond.start_time == 0) {return 0;}

    // uint bondDuration = (block.timestamp - bond.start_time);
    let (block_timestamp) = get_block_timestamp();
    let bondDuration = block_timestamp - bond.start_time;
    let bondDuration256 = Uint256(bondDuration, 0);

    // return bond.lusdAmount * bondDuration / (SECONDS_IN_ONE_HOUR * 100);
    let (res: Uint256) = _calc_accrued_formula(bond.lusd_amount, bondDuration256);

    return (res=res);
}

func _calc_accrued_formula{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    lusd_amount: Uint256, bond_duration: Uint256
) -> (res: Uint256) {
    let MILISECONDS_IN_ONE_HOUR = Uint256(360000, 0);

    let (total: Uint256) = SafeUint256.mul(lusd_amount, bond_duration);
    let (res: Uint256, o: Uint256) = SafeUint256.div_rem(total, MILISECONDS_IN_ONE_HOUR);

    return (res=res);
}

func calcRedemptionFeePercentage{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> (res: Uint256) {
    let fee = 5 * 10 ** 16;
    let res = Uint256(fee, 0);
    return (res=res);
}

@view
func get_id_to_bond_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    id: Uint256
) -> (lusd_amount: Uint256, start_time: felt) {
    tempvar lusd_amount: felt;
    tempvar start_time: felt;

    let (data: BondData) = id_to_bond_data_.read(id=id);

    return (lusd_amount=data.lusd_amount, start_time=data.start_time);
}
