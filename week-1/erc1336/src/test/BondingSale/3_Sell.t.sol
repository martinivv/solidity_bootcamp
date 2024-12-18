// solhint-disable contract-name-camelcase
// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {BaseLayout} from "./_layout.t.sol";
import {IBondingSaleErrors} from "@/interfaces/ICustomErrors.sol";
import {LinearBondingCurve} from "@/libraries/LinearBondingCurve.sol";

/**
 * @notice Test the `sellTokens` function of the `BondingSale` contract.
 */
contract BondingSale_Sell is BaseLayout {
    function setUp() public override {
        super.setUp();
        _dealAccount(user1, 100 ether);

        vm.prank(user1);
        token.buyTokens{value: 1 ether}();
    }

    function test_SellTokensViaTransferAndCall() public {
        vm.prank(user1);
        bool ok = token.transferAndCall(address(token), 1 ether);
        assertTrue(ok);
    }

    function test_SellTokensViaApproveAndCall() public {
        uint256 amountToSell = 1 ether;

        // Approve first
        vm.prank(user1);
        token.approve(address(token), amountToSell);

        // Then call approveAndCall
        vm.prank(user1);
        bool ok = token.approveAndCall(address(token), amountToSell);
        assertTrue(ok);
    }

    function test_SellZeroAmountReverts() public {
        vm.prank(user1);
        token.approve(address(token), 0);

        // Expect revert due to zero amount
        vm.prank(user1);
        vm.expectRevert(IBondingSaleErrors.AmountMustBeGreaterThanZero.selector);
        token.approveAndCall(address(token), 0);
    }

    function test_SellFractionalTokenReverts() public {
        uint256 fractionalTokens = 1.5 ether;
        vm.prank(user1);
        token.approve(address(token), fractionalTokens);

        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(LinearBondingCurve.FractionalAmountNotSupported.selector, fractionalTokens)
        );
        token.approveAndCall(address(token), fractionalTokens);
    }

    function test_SellMoreThanReserveReverts() public {
        vm.startPrank(user2);
        _dealAccount(user2, 10 ether);
        token.buyTokens{value: 1 ether}();
        vm.stopPrank();

        uint256 user2Balance = token.balanceOf(user2);
        uint256 hugeSell = user2Balance;

        vm.startPrank(user2);
        token.approve(address(token), hugeSell);

        // Expect revert due to insufficient reserve
        vm.expectRevert(LinearBondingCurve.InsufficientReserveBalance.selector);
        token.approveAndCall(address(token), hugeSell);
        vm.stopPrank();
    }
}
