// solhint-disable contract-name-camelcase
// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {BaseLayout} from "./_layout.t.sol";
import {IBondingSaleErrors} from "@/interfaces/ICustomErrors.sol";
import {LinearBondingCurve} from "@/libraries/LinearBondingCurve.sol";

/**
 * @notice Test the `buyTokens` function of the `BondingSale` contract.
 */
contract BondingSale_Buy is BaseLayout {
    function setUp() public override {
        super.setUp();
        _dealAccount(user1, 1000 ether);
    }

    function test_BuyWithoutSendingETHReverts() public {
        vm.prank(user1);
        vm.expectRevert(IBondingSaleErrors.AmountMustBeGreaterThanZero.selector);
        token.buyTokens{value: 0}();
    }

    function test_BuyWithFractionalAmountReverts() public {
        uint256 fractionalETH = 1.5 ether;
        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(LinearBondingCurve.FractionalAmountNotSupported.selector, fractionalETH)
        );
        token.buyTokens{value: fractionalETH}();
    }

    function test_SuccessfulBuy() public {
        uint256 amount = 1 ether;
        vm.prank(user1);
        token.buyTokens{value: amount}();

        uint256 ts = token.totalSupply();
        assertTrue(ts > 0);
        assertEq(token.balanceOf(user1), ts);
        assertEq(address(token).balance, token.reserveBalance());
    }

    function test_BuyExceedingCapReverts() public {
        _dealAccount(user1, CAP * 2);
        uint256 bigBuy = CAP * 2;

        vm.prank(user1);
        vm.expectRevert(IBondingSaleErrors.TokenCapExceeded.selector);
        token.buyTokens{value: bigBuy}();
    }

    function test_BuyWithAdjustedMaxGasPrice() public {
        vm.prank(owner);
        token.setMaxGasPrice(300 gwei);

        vm.prank(user1);
        vm.txGasPrice(200 gwei);
        token.buyTokens{value: 1 ether}();
    }
}
