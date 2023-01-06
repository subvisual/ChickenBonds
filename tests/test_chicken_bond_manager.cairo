%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_check,
    uint256_add,
    uint256_sub,
    uint256_mul,
    uint256_unsigned_div_rem,
    uint256_le,
    uint256_lt,
    uint256_eq,
)
from src.ChickenBondManager import BondData
from openzeppelin.security.safemath.library import SafeUint256

@contract_interface
namespace IBondNFT {
    func safeMint(to: felt, tokenId: Uint256, data_len: felt, data: felt*, tokenURI: felt) {
    }

    func mint(to: felt, tokenId: Uint256, tokenURI: felt) {
    }

    func name() -> (name: felt) {
    }

    func balanceOf(account: felt) -> (balance: Uint256) {
    }
}

@contract_interface
namespace IOwnable {
    func transferOwnership(newOwner: felt) {
    }

    func owner() -> (owner: felt) {
    }
}

@contract_interface
namespace IBLUSD {
    func approve(spender: felt, amount: Uint256) -> (success: felt) {
    }
    func mint(to: felt, amount: Uint256) {
    }
    func transferFrom(sender: felt, recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func transfer(recipient: felt, amount: Uint256) -> (success: felt) {
    }
    func balanceOf(account: felt) -> (balance: Uint256) {
    }

    func allowance(owner: felt, spender: felt) -> (remaining: Uint256) {
    }
}

@contract_interface
namespace ILUSD {
    func approve(spender: felt, amount: Uint256) -> (success: felt) {
    }
    func mint(to: felt, amount: Uint256) {
    }
    func transferFrom(sender: felt, recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func transfer(recipient: felt, amount: Uint256) -> (success: felt) {
    }
    func balanceOf(account: felt) -> (balance: Uint256) {
    }

    func allowance(owner: felt, spender: felt) -> (remaining: Uint256) {
    }
}

@contract_interface
namespace ChickenBondManager {
    func create_bond(lusd_amount: Uint256) {
    }

    func chicken_out(_bond_id: Uint256) {
    }

    func chicken_in(_bond_id: Uint256) {
    }

    func redeem(_sLUSD_to_redeem: Uint256) {
    }

    func calc_accrued_SLUD(_bond_id: Uint256) -> (res: Uint256) {
    }

    func _calc_accrued_SLUD(bond: BondData) -> (res: Uint256) {
    }

    func _calc_accrued_formula(lusd_amount: Uint256, bond_duration: Uint256) -> (res: Uint256) {
    }

    func calcRedemptionFeePercentage() -> (res: Uint256) {
    }

    func get_id_to_bond_data(id: Uint256) -> (lusd_amount: Uint256, start_time: felt) {
    }

    func get_lusd_address() -> (lusd_address: felt) {
    }

    func get_bond_address() -> (bond_address: felt) {
    }

    func get_total_pending_LUSD() -> (pending: Uint256) {
    }
}

const ALICE = 111;
const BOB = 112;
const EVE = 113;
const ADMIN = 114;

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local chicken_bonds_: felt;
    local bonds: felt;
    local blusd: felt;
    local lusd: felt;
    local yearn_lusd: felt;

    %{
        context.bond = deploy_contract("./src/BondNFT.cairo", [ids.ADMIN]).contract_address
        context.lusd = deploy_contract("./src/LUSD.cairo", [ids.ADMIN]).contract_address
        context.blusd = deploy_contract("./src/BLUSD.cairo", [ids.ADMIN]).contract_address
        context.curve_pool = deploy_contract("./src/mock/MockCurvePool.cairo", [ids.ADMIN]).contract_address
        context.yearn_lusd = deploy_contract("./src/mock/MockYearnLUSDVault.cairo", [ids.ADMIN, context.lusd]).contract_address
        context.yearn_curve = deploy_contract("./src/mock/MockYearnCurveVault.cairo", [ids.ADMIN]).contract_address
        context.chicken_bonds = deploy_contract("./src/ChickenBondManager.cairo", [context.bond, context.lusd, context.blusd, context.curve_pool, context.yearn_lusd, context.yearn_curve]).contract_address

        ids.chicken_bonds_ = context.chicken_bonds
        ids.bonds= context.bond
        ids.blusd= context.blusd
        ids.lusd= context.lusd
        ids.yearn_lusd= context.yearn_lusd

        stop_prank_bonds = start_prank(ids.ADMIN, target_contract_address= context.bond)
        stop_prank_lusd= start_prank(ids.ADMIN, target_contract_address= context.lusd)
        stop_prank_blusd= start_prank(ids.ADMIN, target_contract_address= context.blusd)
        stop_prank_yearn_lusd = start_prank(ids.ADMIN, target_contract_address= context.yearn_lusd)
    %}

    IOwnable.transferOwnership(contract_address=bonds, newOwner=chicken_bonds_);
    IOwnable.transferOwnership(contract_address=blusd, newOwner=chicken_bonds_);
    IOwnable.transferOwnership(contract_address=yearn_lusd, newOwner=chicken_bonds_);

    %{
        stop_prank_bonds()
        stop_prank_lusd()
        stop_prank_blusd()
        stop_prank_yearn_lusd()

    %}

    return ();
}

@external
func test_create_bond{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    local lusd_: felt;
    local bonds_: felt;
    local chicken_bonds_: felt;
    local yearn_lusd_: felt;
    local alice: felt;
    local admin: felt;

    %{
        ids.lusd_ = context.lusd
        stop_prank_lusd= start_prank(ids.ADMIN, target_contract_address= context.lusd)
    %}
    ILUSD.mint(contract_address=lusd_, to=ALICE, amount=Uint256(100000, 0));

    let (balance) = ILUSD.balanceOf(contract_address=lusd_, account=ALICE);

    let (currect_balance) = uint256_eq(balance, Uint256(100000, 0));

    assert currect_balance = 1;

    %{
        stop_prank_lusd()
        ids.chicken_bonds_ = context.chicken_bonds
        ids.yearn_lusd_ = context.yearn_lusd
        stop_prank_lusd = start_prank(ids.ALICE, target_contract_address= context.lusd)
    %}
    ILUSD.approve(contract_address=lusd_, spender=chicken_bonds_, amount=Uint256(100000, 0));
    ILUSD.approve(contract_address=lusd_, spender=yearn_lusd_, amount=Uint256(100000, 0));

    let (allowance) = ILUSD.allowance(contract_address=lusd_, owner=ALICE, spender=chicken_bonds_);
    let (check_allowance) = uint256_eq(allowance, Uint256(100000, 0));
    assert check_allowance = 1;

    %{
        stop_prank_lusd()
        ids.chicken_bonds_ = context.chicken_bonds
        ids.bonds_ = context.bond
        stop_prank_manager = start_prank(ids.ALICE, target_contract_address= context.chicken_bonds)
    %}

    ChickenBondManager.create_bond(contract_address=chicken_bonds_, lusd_amount=Uint256(50000, 0));

    let (pending) = ChickenBondManager.get_total_pending_LUSD(contract_address=chicken_bonds_);

    let (currect_pending) = uint256_eq(pending, Uint256(50000, 0));

    assert currect_pending = 1;

    let (balance) = ILUSD.balanceOf(contract_address=yearn_lusd_, account=chicken_bonds_);

    let (currect_balance) = uint256_eq(balance, Uint256(50000, 0));

    assert currect_balance = 1;

    let (balancee) = IBondNFT.balanceOf(contract_address=bonds_, account=ALICE);

    let (currect_balancee) = uint256_eq(balancee, Uint256(1, 0));

    assert currect_balancee = 1;

    %{ stop_prank_manager() %}

    return ();
}

@external
func test_chicken_out{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    local lusd_: felt;
    local bonds_: felt;
    local chicken_bonds_: felt;
    local yearn_lusd_: felt;
    local alice: felt;
    local admin: felt;

    %{
        ids.lusd_ = context.lusd
        stop_prank_lusd= start_prank(ids.ADMIN, target_contract_address= context.lusd)
    %}
    ILUSD.mint(contract_address=lusd_, to=ALICE, amount=Uint256(100000, 0));

    let (balance) = ILUSD.balanceOf(contract_address=lusd_, account=ALICE);

    let (currect_balance) = uint256_eq(balance, Uint256(100000, 0));

    assert currect_balance = 1;

    %{
        stop_prank_lusd()
        ids.chicken_bonds_ = context.chicken_bonds
        ids.yearn_lusd_ = context.yearn_lusd
        stop_prank_lusd = start_prank(ids.ALICE, target_contract_address= context.lusd)
    %}
    ILUSD.approve(contract_address=lusd_, spender=chicken_bonds_, amount=Uint256(100000, 0));
    ILUSD.approve(contract_address=lusd_, spender=yearn_lusd_, amount=Uint256(100000, 0));

    let (allowance) = ILUSD.allowance(contract_address=lusd_, owner=ALICE, spender=chicken_bonds_);
    let (check_allowance) = uint256_eq(allowance, Uint256(100000, 0));
    assert check_allowance = 1;

    %{
        stop_prank_lusd()
        ids.chicken_bonds_ = context.chicken_bonds
        ids.bonds_ = context.bond
        stop_prank_manager = start_prank(ids.ALICE, target_contract_address= context.chicken_bonds)
    %}

    ChickenBondManager.create_bond(contract_address=chicken_bonds_, lusd_amount=Uint256(50000, 0));

    let (pending) = ChickenBondManager.get_total_pending_LUSD(contract_address=chicken_bonds_);

    let (currect_pending) = uint256_eq(pending, Uint256(50000, 0));

    assert currect_pending = 1;

    let (balance) = ILUSD.balanceOf(contract_address=yearn_lusd_, account=chicken_bonds_);

    let (currect_balance) = uint256_eq(balance, Uint256(50000, 0));

    assert currect_balance = 1;

    let (balancee) = IBondNFT.balanceOf(contract_address=bonds_, account=ALICE);

    let (currect_balancee) = uint256_eq(balancee, Uint256(1, 0));

    assert currect_balancee = 1;

    %{
        stop_prank_manager()
        ids.chicken_bonds_ = context.chicken_bonds
        ids.bonds_ = context.bond
        stop_prank_manager = start_prank(ids.ALICE, target_contract_address= context.chicken_bonds)
    %}

    ChickenBondManager.chicken_out(contract_address=chicken_bonds_, _bond_id=Uint256(1, 0));

    let (balance) = ILUSD.balanceOf(contract_address=lusd_, account=chicken_bonds_);

    let (currect_balance) = uint256_eq(balance, Uint256(0, 0));

    assert currect_balance = 1;

    let (balance) = ILUSD.balanceOf(contract_address=lusd_, account=ALICE);

    let (currect_balance) = uint256_eq(balance, Uint256(100000, 0));

    assert currect_balance = 1;

    let (balancee) = IBondNFT.balanceOf(contract_address=bonds_, account=ALICE);

    let (currect_balancee) = uint256_eq(balancee, Uint256(0, 0));

    assert currect_balancee = 1;

    %{ stop_prank_manager() %}

    return ();
}

@external
func test_chicken_in{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    local lusd_: felt;
    local blusd_: felt;
    local bonds_: felt;
    local chicken_bonds_: felt;
    local yearn_lusd_: felt;
    local alice: felt;
    local admin: felt;

    %{
        ids.lusd_ = context.lusd
        ids.blusd_ = context.blusd
        stop_prank_lusd= start_prank(ids.ADMIN, target_contract_address= context.lusd)
    %}
    ILUSD.mint(contract_address=lusd_, to=ALICE, amount=Uint256(100000, 0));

    let (balance) = ILUSD.balanceOf(contract_address=lusd_, account=ALICE);

    let (currect_balance) = uint256_eq(balance, Uint256(100000, 0));

    assert currect_balance = 1;

    %{
        stop_prank_lusd()
        ids.chicken_bonds_ = context.chicken_bonds
        ids.yearn_lusd_ = context.yearn_lusd
        stop_prank_lusd = start_prank(ids.ALICE, target_contract_address= context.lusd)
    %}
    ILUSD.approve(contract_address=lusd_, spender=chicken_bonds_, amount=Uint256(100000, 0));
    ILUSD.approve(contract_address=lusd_, spender=yearn_lusd_, amount=Uint256(100000, 0));

    let (allowance) = ILUSD.allowance(contract_address=lusd_, owner=ALICE, spender=chicken_bonds_);
    let (check_allowance) = uint256_eq(allowance, Uint256(100000, 0));
    assert check_allowance = 1;

    %{
        stop_prank_lusd()
        ids.chicken_bonds_ = context.chicken_bonds
        ids.bonds_ = context.bond
        stop_prank_manager = start_prank(ids.ALICE, target_contract_address= context.chicken_bonds)
    %}

    ChickenBondManager.create_bond(contract_address=chicken_bonds_, lusd_amount=Uint256(50000, 0));

    let (pending) = ChickenBondManager.get_total_pending_LUSD(contract_address=chicken_bonds_);

    let (currect_pending) = uint256_eq(pending, Uint256(50000, 0));

    assert currect_pending = 1;

    let (balance) = ILUSD.balanceOf(contract_address=yearn_lusd_, account=chicken_bonds_);

    let (currect_balance) = uint256_eq(balance, Uint256(50000, 0));

    assert currect_balance = 1;

    let (balancee) = IBondNFT.balanceOf(contract_address=bonds_, account=ALICE);

    let (currect_balancee) = uint256_eq(balancee, Uint256(1, 0));

    assert currect_balancee = 1;

    %{
        stop_prank_manager()
        ids.chicken_bonds_ = context.chicken_bonds
        ids.bonds_ = context.bond
        stop_prank_manager = start_prank(ids.ALICE, target_contract_address= context.chicken_bonds)
    %}

    ChickenBondManager.chicken_in(contract_address=chicken_bonds_, _bond_id=Uint256(1, 0));

    let (pending) = ChickenBondManager.get_total_pending_LUSD(contract_address=chicken_bonds_);

    let (currect_pending) = uint256_eq(pending, Uint256(0, 0));

    assert currect_pending = 1;

    let (balance) = ILUSD.balanceOf(contract_address=yearn_lusd_, account=chicken_bonds_);

    let (currect_balance) = uint256_eq(balance, Uint256(50000, 0));

    assert currect_balance = 1;

    let (balance) = ILUSD.balanceOf(contract_address=lusd_, account=ALICE);

    let (currect_balance) = uint256_eq(balance, Uint256(50000, 0));

    assert currect_balance = 1;

    let (balance) = IBLUSD.balanceOf(contract_address=blusd_, account=ALICE);

    let (currect_balance) = uint256_eq(balance, Uint256(0, 0));

    assert currect_balance = 1;

    let (balancee) = IBondNFT.balanceOf(contract_address=bonds_, account=ALICE);

    let (currect_balancee) = uint256_eq(balancee, Uint256(0, 0));

    assert currect_balancee = 1;

    %{ stop_prank_manager() %}

    return ();
}

@external
func test_chicken_in_after_timelapse{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;
    local lusd_: felt;
    local blusd_: felt;
    local bonds_: felt;
    local chicken_bonds_: felt;
    local yearn_lusd_: felt;
    local alice: felt;
    local admin: felt;

    %{
        ids.lusd_ = context.lusd
        ids.blusd_ = context.blusd
        stop_prank_lusd= start_prank(ids.ADMIN, target_contract_address= context.lusd)
    %}
    ILUSD.mint(contract_address=lusd_, to=ALICE, amount=Uint256(100000, 0));

    let (balance) = ILUSD.balanceOf(contract_address=lusd_, account=ALICE);

    let (currect_balance) = uint256_eq(balance, Uint256(100000, 0));

    assert currect_balance = 1;

    %{
        stop_prank_lusd()
        ids.chicken_bonds_ = context.chicken_bonds
        ids.yearn_lusd_ = context.yearn_lusd
        stop_prank_lusd = start_prank(ids.ALICE, target_contract_address= context.lusd)
    %}
    ILUSD.approve(contract_address=lusd_, spender=chicken_bonds_, amount=Uint256(100000, 0));
    ILUSD.approve(contract_address=lusd_, spender=yearn_lusd_, amount=Uint256(100000, 0));

    let (allowance) = ILUSD.allowance(contract_address=lusd_, owner=ALICE, spender=chicken_bonds_);
    let (check_allowance) = uint256_eq(allowance, Uint256(100000, 0));
    assert check_allowance = 1;

    %{
        stop_prank_lusd()
        ids.chicken_bonds_ = context.chicken_bonds
        ids.bonds_ = context.bond
        stop_prank_manager = start_prank(ids.ALICE, target_contract_address= context.chicken_bonds)
    %}

    ChickenBondManager.create_bond(contract_address=chicken_bonds_, lusd_amount=Uint256(50000, 0));

    let (pending) = ChickenBondManager.get_total_pending_LUSD(contract_address=chicken_bonds_);

    let (currect_pending) = uint256_eq(pending, Uint256(50000, 0));

    assert currect_pending = 1;

    let (balance) = ILUSD.balanceOf(contract_address=yearn_lusd_, account=chicken_bonds_);

    let (currect_balance) = uint256_eq(balance, Uint256(50000, 0));

    assert currect_balance = 1;

    let (balancee) = IBondNFT.balanceOf(contract_address=bonds_, account=ALICE);

    let (currect_balancee) = uint256_eq(balancee, Uint256(1, 0));

    assert currect_balancee = 1;

    %{
        stop_prank_manager()
        ids.chicken_bonds_ = context.chicken_bonds
        ids.bonds_ = context.bond
        stop_prank_manager = start_prank(ids.ALICE, target_contract_address= context.chicken_bonds)
        stop_warp = warp(360000, target_contract_address= context.chicken_bonds)
    %}

    ChickenBondManager.chicken_in(contract_address=chicken_bonds_, _bond_id=Uint256(1, 0));

    let (pending) = ChickenBondManager.get_total_pending_LUSD(contract_address=chicken_bonds_);

    let (currect_pending) = uint256_eq(pending, Uint256(0, 0));

    assert currect_pending = 1;

    let (balance) = ILUSD.balanceOf(contract_address=yearn_lusd_, account=chicken_bonds_);

    let (currect_balance) = uint256_eq(balance, Uint256(50000, 0));

    assert currect_balance = 1;

    let (balance) = ILUSD.balanceOf(contract_address=lusd_, account=ALICE);

    let (currect_balance) = uint256_eq(balance, Uint256(50000, 0));

    assert currect_balance = 1;

    let (balance) = IBLUSD.balanceOf(contract_address=blusd_, account=ALICE);

    let (currect_balance) = uint256_eq(balance, Uint256(50000, 0));

    assert currect_balance = 1;

    let (balancee) = IBondNFT.balanceOf(contract_address=bonds_, account=ALICE);

    let (currect_balancee) = uint256_eq(balancee, Uint256(0, 0));

    assert currect_balancee = 1;

    %{ stop_prank_manager() %}

    return ();
}

@external
func test_redeem{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    local lusd_: felt;
    local blusd_: felt;
    local bonds_: felt;
    local chicken_bonds_: felt;
    local yearn_lusd_: felt;
    local alice: felt;
    local admin: felt;

    %{
        ids.lusd_ = context.lusd
        ids.blusd_ = context.blusd
        stop_prank_lusd= start_prank(ids.ADMIN, target_contract_address= context.lusd)
    %}
    ILUSD.mint(contract_address=lusd_, to=ALICE, amount=Uint256(100000, 0));

    %{
        stop_prank_lusd()
        ids.chicken_bonds_ = context.chicken_bonds
        ids.yearn_lusd_ = context.yearn_lusd
        stop_prank_lusd = start_prank(ids.ALICE, target_contract_address= context.lusd)
    %}
    ILUSD.approve(contract_address=lusd_, spender=chicken_bonds_, amount=Uint256(100000, 0));
    ILUSD.approve(contract_address=lusd_, spender=yearn_lusd_, amount=Uint256(100000, 0));
    IBLUSD.approve(contract_address=blusd_, spender=chicken_bonds_, amount=Uint256(100000, 0));

    %{
        stop_prank_lusd()
        ids.chicken_bonds_ = context.chicken_bonds
        ids.bonds_ = context.bond
        stop_prank_manager = start_prank(ids.ALICE, target_contract_address= context.chicken_bonds)
    %}

    ChickenBondManager.create_bond(contract_address=chicken_bonds_, lusd_amount=Uint256(50000, 0));

    %{
        stop_prank_manager()
        ids.chicken_bonds_ = context.chicken_bonds
        ids.bonds_ = context.bond
        stop_prank_manager = start_prank(ids.ALICE, target_contract_address= context.chicken_bonds)
        stop_warp = warp(360000, target_contract_address= context.chicken_bonds)
    %}

    ChickenBondManager.chicken_in(contract_address=chicken_bonds_, _bond_id=Uint256(1, 0));

    // test redeem

    let (balance) = IBLUSD.balanceOf(contract_address=blusd_, account=ALICE);

    let (currect_balance) = uint256_eq(balance, Uint256(50000, 0));

    assert currect_balance = 1;

    let (balance) = ILUSD.balanceOf(contract_address=lusd_, account=ALICE);

    let (currect_balance) = uint256_eq(balance, Uint256(50000, 0));

    assert currect_balance = 1;

    let (balance) = ILUSD.balanceOf(contract_address=lusd_, account=yearn_lusd_);

    let (currect_balance) = uint256_eq(balance, Uint256(50000, 0));

    assert currect_balance = 1;

    let (balance) = ILUSD.balanceOf(contract_address=lusd_, account=chicken_bonds_);

    let (currect_balance) = uint256_eq(balance, Uint256(0, 0));

    assert currect_balance = 1;

    ChickenBondManager.redeem(contract_address=chicken_bonds_, _sLUSD_to_redeem=Uint256(50000, 0));

    let (balance) = IBLUSD.balanceOf(contract_address=blusd_, account=ALICE);

    let (currect_balance) = uint256_eq(balance, Uint256(0, 0));

    assert currect_balance = 1;

    let (balance) = ILUSD.balanceOf(contract_address=lusd_, account=ALICE);

    let (currect_balance) = uint256_eq(balance, Uint256(97500, 0));

    assert currect_balance = 1;

    let (balance) = ILUSD.balanceOf(contract_address=lusd_, account=yearn_lusd_);

    let (currect_balance) = uint256_eq(balance, Uint256(2500, 0));

    assert currect_balance = 1;

    let (balance) = ILUSD.balanceOf(contract_address=lusd_, account=chicken_bonds_);

    let (currect_balance) = uint256_eq(balance, Uint256(0, 0));

    assert currect_balance = 1;

    %{ stop_prank_manager() %}

    return ();
}
