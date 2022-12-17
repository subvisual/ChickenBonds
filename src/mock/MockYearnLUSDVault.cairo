// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from openzeppelin.token.erc20.library import ERC20
from openzeppelin.access.ownable.library import Ownable

@contract_interface
namespace ILUSD {
    func transferFrom(sender: felt, recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func transfer(recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func balanceOf(account: felt) -> (balance: Uint256) {
    }
}

@storage_var
func token_address_() -> (res: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, token_address
) {
    ERC20.initializer('YearnLUSD', 'YearnLUSD', 18);
    Ownable.initializer(owner);
    token_address_.write(token_address);
    return ();
}

//
// Getters
//

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    return ERC20.name();
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    return ERC20.symbol();
}

@view
func totalSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    totalSupply: Uint256
) {
    let (totalSupply) = ERC20.total_supply();
    return (totalSupply=totalSupply);
}

@view
func decimals{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    decimals: felt
) {
    return ERC20.decimals();
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) -> (
    balance: Uint256
) {
    return ERC20.balance_of(account);
}

@view
func allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, spender: felt
) -> (remaining: Uint256) {
    return ERC20.allowance(owner, spender);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    return Ownable.owner();
}

//
// Externals
//

@external
func transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    recipient: felt, amount: Uint256
) -> (success: felt) {
    return ERC20.transfer(recipient, amount);
}

@external
func transferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sender: felt, recipient: felt, amount: Uint256
) -> (success: felt) {
    return ERC20.transfer_from(sender, recipient, amount);
}

@external
func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spender: felt, amount: Uint256
) -> (success: felt) {
    return ERC20.approve(spender, amount);
}

@external
func increaseAllowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spender: felt, added_value: Uint256
) -> (success: felt) {
    return ERC20.increase_allowance(spender, added_value);
}

@external
func decreaseAllowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spender: felt, subtracted_value: Uint256
) -> (success: felt) {
    return ERC20.decrease_allowance(spender, subtracted_value);
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    return ();
}

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.renounce_ownership();
    return ();
}

@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, amount: Uint256
) {
    Ownable.assert_only_owner();
    ERC20._mint(to, amount);
    return ();
}

@external
func deposit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _tokenAmount: Uint256
) {
    alloc_locals;
    let (caller_address) = get_caller_address();
    let (this_contract_address) = get_contract_address();
    let (lusd_address) = token_address_.read();
    ILUSD.transferFrom(
        contract_address=lusd_address,
        sender=caller_address,
        recipient=this_contract_address,
        amount=_tokenAmount,
    );

    let (lp_shares) = calcTokenToYToken(_tokenAmount);
    ERC20._mint(caller_address, lp_shares);

    return ();
}

@external
func withdraw{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _lp_shares: Uint256
) {
    alloc_locals;
    let (_tokenAmount) = calcTokenToYToken(_lp_shares);

    let (caller_address) = get_caller_address();
    let (this_contract_address) = get_contract_address();
    let (lusd_address) = token_address_.read();

    ILUSD.transfer(contract_address=lusd_address, recipient=caller_address, amount=_tokenAmount);

    ERC20._burn(caller_address, _lp_shares);
    return ();
}

@external
func calcTokenToYToken(_tokenAmount: Uint256) -> (res: Uint256) {
    return (res=_tokenAmount);
}

@external
func calcYTokenToToken(_yTokenAmount: Uint256) -> (res: Uint256) {
    return (res=_yTokenAmount);
}
