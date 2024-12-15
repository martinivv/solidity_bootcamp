// solhint-disable contract-name-camelcase
// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase
// solhint-disable max-line-length
// solhint-disable ordering

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {BaseLayout} from "@/test/GovernedToken/_layout.t.sol";
import {IGovernedTokenErrors} from "@/interfaces/ICustomErrors.sol";

contract GovernedToken_Attack is BaseLayout {
    function setUp() public override {
        super.setUp();
    }

    function mintForAccount(address account_, uint256 amount_) internal {
        vm.prank(owner);
        MY_TOKEN_.mint(account_, amount_);
    }

    /* ============================================================================================== */
    /*                                             ATTACK                                             */
    /* ============================================================================================== */

    function test_TransferZeroTokens() public {
        uint256 initialBalance = MY_TOKEN_.balanceOf(owner);
        vm.prank(owner);
        MY_TOKEN_.transfer(user1, 0);
        assertEq(MY_TOKEN_.balanceOf(owner), initialBalance);
    }

    function test_SupremeTransfer_ZeroAmount() public {
        uint256 initBalanceFrom = MY_TOKEN_.balanceOf(owner);
        uint256 initBalanceTo = MY_TOKEN_.balanceOf(user1);

        vm.prank(owner);
        bool ok = MY_TOKEN_.supremeTransfer(owner, user1, 0);

        assertTrue(ok);
        assertEq(MY_TOKEN_.balanceOf(owner), initBalanceFrom);
        assertEq(MY_TOKEN_.balanceOf(user1), initBalanceTo);
    }

    /* ============================================================================================== */
    /*                                           FUZZ TESTS                                           */
    /* ============================================================================================== */

    function testFuzz_RestrictedTransfer(address account) public {
        vm.assume(account != address(0) && account != owner);

        mintForAccount(account, TEST_AMOUNT);
        vm.startPrank(owner);
        MY_TOKEN_.updateRestriction(account, MY_TOKEN_.SEND_RESTRICTION());
        vm.stopPrank();

        vm.startPrank(account);
        vm.expectRevert(abi.encodeWithSelector(IGovernedTokenErrors.RestrictedAccount.selector, account));
        MY_TOKEN_.transfer(user1, TEST_AMOUNT);
        vm.stopPrank();
    }

    /* ... */
}
