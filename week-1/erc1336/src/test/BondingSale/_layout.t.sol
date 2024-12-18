// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {BondingSale} from "@/contracts/BondingSale.sol";

/**
 * @notice Base layout for testing the `BondingSale` contract.
 */
contract BaseLayout is Test {
    BondingSale internal token;

    address internal owner;
    address internal user1;
    address internal user2;

    uint256 internal constant SCALE = 1e18;

    string internal constant NAME = "Bonding Token";
    string internal constant SYMBOL = "BOND";
    uint256 internal constant CAP = 100_000_000 * SCALE;
    uint256 internal constant INITIAL_PRICE = 1 ether;
    uint256 internal constant SLOPE = 1 ether;

    function setUp() public virtual {
        owner = vm.addr(99);
        vm.label(owner, "Owner");

        user1 = vm.addr(1);
        vm.label(user1, "User1");

        user2 = vm.addr(2);
        vm.label(user2, "User2");

        vm.prank(owner);
        token = new BondingSale(NAME, SYMBOL, CAP, INITIAL_PRICE, SLOPE);
    }

    function _dealAccount(address account, uint256 value) internal {
        vm.deal(account, value);
    }
}
