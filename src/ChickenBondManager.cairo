// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address )
from starkware.cairo.common.alloc import alloc

@contract_interface
namespace IBondNFT {
    func safeMint(to: felt, tokenId: Uint256, data_len: felt, data: felt*, tokenURI: felt) {
    }
}

@contract_interface
namespace IBLUSD {
    func mint(to: felt, amount: Uint256) {
    }
}

@contract_interface
namespace ILUSD {
    func transfer_from( sender: felt, recipient: felt, amount: Uint256) -> (success: felt) {
    }
}

@contract_interface
namespace ICurvePool {
    func add_liquidity(_LUSD3CRVAmount: felt) {
    }

    func remove_liquidity(_LUSD3CRVAmount: felt) {
    }

    func calcLUSDToLUSD3CRV(_LUSD3CRVAmount: felt) {
    }

    func calcLUSD3CRVToLUSD(_LUSD3CRVAmount: felt) {
    }
}

@contract_interface
namespace IMockYearnVault {
    func deposit(_tokenAmount: felt) {
    }

    func withdraw(_tokenAmount: felt) {
    }

    func calcTokenToYToken(_tokenAmount: felt) {
    }

    func calcYTokenToToken(_yTokenAmount: felt) {
    }
}

@storage_var
func lusd_address() -> (value: felt) {
}

@storage_var
func blusd_address() -> (value: felt) {
}

@storage_var
func bond_address() -> (value: felt) {
}
@storage_var
func mock_yearn_vault_address() -> (value: felt) {
}

@storage_var
func mock_curve_pool_address() -> (value: felt) {
}

struct BondData {
    lusd_amount: felt,
    start_time: felt,
}

@storage_var
func id_to_bond_data(id: Uint256) -> (data: BondData) {
}

@storage_var
func total_pending_LUSD() -> (value: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _bond_address: felt,
    _lusd_address: felt,
    _blusd_address: felt,
    _mock_yearn_vault_address: felt,
    _mock_curve_pool_address: felt,
) {
    bond_address.write(_bond_address);
    lusd_address.write(_lusd_address);
    blusd_address.write(_blusd_address);
    mock_yearn_vault_address.write(_mock_yearn_vault_address);
    mock_curve_pool_address.write(_mock_curve_pool_address);

    return ();
}

@external
func create_bond{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    lusd_amount: felt//, value: felt
) {
    alloc_locals;
    let (caller_address) = get_caller_address();

    let token_id: Uint256 = Uint256(1, 0);
    let len: felt = 3;

    // Allocate an array.
    let (ptr) = alloc();

    // Populate some values in the array.
    assert [ptr] = 9;
    assert [ptr + 1] = 16;
    assert [ptr + 2] = 25;

     let (value)  = bond_address.read();

    IBondNFT.safeMint(
        contract_address=value,
        to=caller_address,
        tokenId=token_id,
        data_len=len,
        data=ptr,
        tokenURI=len,
    );

    let (timestamp) = get_block_timestamp();
    let bond_data: BondData = BondData(lusd_amount=lusd_amount, start_time=timestamp);

    id_to_bond_data.write(token_id, bond_data);

    let (total_pending) = total_pending_LUSD.read();
    total_pending_LUSD.write(total_pending + lusd_amount);

    let (this_contract_address) = get_contract_address();

     let (lusd_add)  = lusd_address.read();
     let lusd_amount_256 = Uint256(lusd_amount,0);
    ILUSD.transfer_from(contract_address=lusd_add,sender=caller_address, recipient=this_contract_address, amount=lusd_amount_256);

     let (yearn_add)  = mock_yearn_vault_address.read();
    IMockYearnVault.deposit(contract_address=yearn_add, _tokenAmount= lusd_amount);

    return ();
}


//https://github.com/liquity/ChickenBond/blob/f51be4cec25f941a030ccc68d4bf2b66d1340674/LUSDChickenBonds/src/ChickenBondManager.sol
@external
func chicken_out{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    //requires caller be bond owner

    
) {
    
}

@external
func chicken_in{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    arguments
) {
    
}

@view
func get_id_to_bond_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    id: Uint256
) -> (lusd_amount: felt, start_time: felt) {
    tempvar lusd_amount: felt;
    tempvar start_time: felt;

    let (data: BondData) = id_to_bond_data.read(id=id);

    return (lusd_amount=data.lusd_amount, start_time=data.start_time);
}
