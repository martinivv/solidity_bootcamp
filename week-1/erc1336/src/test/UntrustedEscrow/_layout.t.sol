// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {UntrustedEscrow} from "@/contracts/UntrustedEscrow.sol";

/**
 * @notice Base layout for testing the `UntrustedEscrow` contract.
 */
contract BaseLayout is Test {
    UntrustedEscrow internal token;

    address internal owner;
    address internal user1;
    address internal user2;

    function setUp() public virtual {
        owner = vm.addr(99);
        vm.label(owner, "Owner");

        user1 = vm.addr(1);
        vm.label(user1, "User1");

        user2 = vm.addr(2);
        vm.label(user2, "User2");

        vm.prank(owner);
        token = new UntrustedEscrow();
    }
}
