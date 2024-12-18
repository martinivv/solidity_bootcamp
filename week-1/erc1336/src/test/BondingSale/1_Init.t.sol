// solhint-disable contract-name-camelcase
// solhint-disable func-name-mixedcase
// solhint-disable ordering

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {BaseLayout} from "./_layout.t.sol";
import {IBondingSale} from "@/interfaces/IBondingSale.sol";

/**
 * @notice Test the initialization of the `BondingSale` contract.
 */
contract BondingSale_Init is BaseLayout {
    function test_InitialValues() public view {
        assertEq(token.name(), NAME);
        assertEq(token.symbol(), SYMBOL);
        assertEq(token.cap(), CAP);
        assertEq(token.INITIAL_PRICE(), INITIAL_PRICE);
        assertEq(token.SLOPE(), SLOPE);

        assertEq(token.totalSupply(), 0);
        assertEq(token.owner(), owner);
    }

    function test_SupportsInterface() public view {
        assertTrue(token.supportsInterface(type(IBondingSale).interfaceId));
    }

    function test_MaxGasPriceDefault() public view {
        assertEq(token.maxGasPrice(), 100 gwei);
    }

    function test_OwnerCanSetMaxGasPrice() public {
        vm.prank(owner);
        token.setMaxGasPrice(200 gwei);
        assertEq(token.maxGasPrice(), 200 gwei);
    }

    function test_NonOwnerCannotSetMaxGasPrice() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        token.setMaxGasPrice(200 gwei);
    }
}
