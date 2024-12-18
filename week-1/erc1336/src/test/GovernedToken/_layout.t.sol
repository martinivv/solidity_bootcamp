// solhint-disable var-name-mixedcase

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {GovernedToken} from "@/contracts/GovernedToken.sol";

/**
 * @notice Base layout for testing the `GovernedToken` contract.
 */
contract BaseLayout is Test {
    GovernedToken internal token;

    address internal owner;
    address internal user1;
    address internal user2;
    address internal restrictedUser;

    uint256 internal constant TEST_AMOUNT = 100 * 1e18;

    string internal constant NAME = "Governed Token";
    string internal constant SYMBOL = "GTN";
    uint256 internal constant CAP = 100_000_000_000 * 1e18;
    uint256 internal constant INITIAL_SUPPLY = 100_000_000 * 1e18;

    function setUp() public virtual {
        owner = vm.addr(99);
        vm.label(owner, "Owner");

        user1 = vm.addr(1);
        vm.label(user1, "User1");

        user2 = vm.addr(2);
        vm.label(user2, "User2");

        restrictedUser = vm.addr(3);
        vm.label(restrictedUser, "RestrictedUser");

        vm.prank(owner);
        token = new GovernedToken(NAME, SYMBOL, CAP);
    }
}
