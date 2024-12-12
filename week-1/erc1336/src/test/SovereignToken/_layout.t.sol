// solhint-disable var-name-mixedcase

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import {Test} from "forge-std/Test.sol";
import {SovereignToken} from "@/contracts/SovereignToken.sol";

contract BaseLayout is Test {
    SovereignToken internal MY_TOKEN_;

    address internal owner;
    address internal user1;
    address internal user2;
    address internal bannedUser;

    string internal constant NAME = "Test Token";
    string internal constant SYMBOL = "TTN";
    uint256 internal constant CAP = 100_000_000 * 1e18;
    uint256 internal constant TEST_AMOUNT = 100 * 1e18;

    function setUp() public virtual {
        owner = vm.addr(99);
        vm.label(owner, "owner");

        user1 = vm.addr(1);
        vm.label(user1, "user1");

        user2 = vm.addr(2);
        vm.label(user2, "user2");

        bannedUser = vm.addr(3);
        vm.label(bannedUser, "bannedUser");

        vm.prank(owner);
        MY_TOKEN_ = new SovereignToken(NAME, SYMBOL, CAP);
    }
}
