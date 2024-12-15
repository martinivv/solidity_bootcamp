// solhint-disable var-name-mixedcase

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {GovernedToken} from "@/contracts/GovernedToken.sol";

contract BaseLayout is Test {
    GovernedToken internal MY_TOKEN_;

    address internal owner;
    address internal user1;
    address internal user2;
    address internal restrictedUser;

    string internal constant NAME = "Governed Token";
    string internal constant SYMBOL = "GTN";
    uint256 internal constant CAP = 100_000_000_000 * 1e18;
    uint256 internal constant INITIAL_SUPPLY = 100_000_000 * 1e18;
    uint256 internal constant TEST_AMOUNT = 100 * 1e18;

    function setUp() public virtual {
        owner = vm.addr(99);
        vm.label(owner, "owner");

        user1 = vm.addr(1);
        vm.label(user1, "user1");

        user2 = vm.addr(2);
        vm.label(user2, "user2");

        restrictedUser = vm.addr(3);
        vm.label(restrictedUser, "restrictedUser");

        vm.prank(owner);
        MY_TOKEN_ = new GovernedToken(NAME, SYMBOL, CAP);
    }
}
