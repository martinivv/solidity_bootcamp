// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC1363Receiver} from "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";
import {IERC1363Spender} from "@openzeppelin/contracts/interfaces/IERC1363Spender.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

import {BaseBondingSale} from "@/contracts/BaseBondingSale.sol";
import {LinearBondingCurve} from "@/libraries/LinearBondingCurve.sol";
import {IBondingSale} from "@/interfaces/IBondingSale.sol";
import {IBondingSaleErrors} from "@/interfaces/ICustomErrors.sol";

/**
 * @notice Implements a token sale mechanism using a linear bonding curve.
 *         ERC1363 token compliance is enforced.
 * @author Martin Ivanov
 */
contract BondingSale is
    IBondingSale,
    Ownable,
    BaseBondingSale,
    IERC1363Receiver,
    IERC1363Spender,
    ReentrancyGuardTransient
{
    using LinearBondingCurve for uint256;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 _initialPrice,
        uint256 _slope
    )
        Ownable(msg.sender)
        BaseBondingSale(name_, symbol_, maxSupply_, _initialPrice, _slope)
    {}

    /* ============================================================================================== */
    /*                                        PUBLIC FUNCTIONS                                        */
    /* ============================================================================================== */

    /**
     * @notice Allows users to accumulate tokens by sending ETH. The token price is
     *         determined by the bonding curve.
     * @dev By enforcing max gas price SOME front-run attack vectors are mitigated.
     */
    function buyTokens() external payable nonReentrant {
        maxGasPrice.enforceGasPrice();

        uint256 _ethAmountSent = msg.value;
        if (_ethAmountSent == 0) {
            revert IBondingSaleErrors.AmountMustBeGreaterThanZero();
        }
        _ethAmountSent.enforceNotFraction();

        _buy(msg.sender, _ethAmountSent);
    }

    /**
     * @notice Handles the sale of tokens through ERC1363 {transferAndCall}.
     *         Burns the tokens and returns ETH based on the bonding curve.
     */
    function onTransferReceived(
        address operator,
        address,
        uint256 value,
        bytes calldata
    )
        external
        override(IBondingSale, IERC1363Receiver)
        onlyContractReceiver
        nonReentrant
        returns (bytes4)
    {
        _sell(operator, value);
        return IERC1363Receiver.onTransferReceived.selector;
    }

    /**
     * @notice Handles the sale of tokens through ERC1363 {approveAndCall}.
     *         Burns the tokens and returns ETH based on the bonding curve.
     */
    function onApprovalReceived(
        address owner,
        uint256 value,
        bytes calldata
    )
        external
        override(IBondingSale, IERC1363Spender)
        onlyContractReceiver
        nonReentrant
        returns (bytes4)
    {
        transferFrom(owner, address(this), value);
        _sell(owner, value);
        return IERC1363Spender.onApprovalReceived.selector;
    }

    /* ============================================================================================== */
    /*                                    ADMINISTRATIVE FUNCTIONS                                    */
    /* ============================================================================================== */

    /**
     * @notice Sets the maximum gas price for the contract.
     *
     * NOTE: While setting `maxGasPrice` and using it in {enforceGasPrice} has its advantages, it may
     *      sometimes need to be manually adjusted.
     */
    function setMaxGasPrice(uint256 _gasPrice) external onlyOwner {
        maxGasPrice = _gasPrice;
        emit MaxGasPriceUpdated(_gasPrice);
    }

    /* ============================================================================================== */
    /*                                      VIEW FUNCTIONS                                            */
    /* ============================================================================================== */

    /**
     * @notice Returns the number of tokens that can be purchased with a given amount of ETH.
     */
    function calculateTokenAmountForEth(uint256 ethAmount) external view returns (uint256) {
        return totalSupply().calculateBuyCost(ethAmount, INITIAL_PRICE, SLOPE);
    }

    /**
     * @notice Returns the amount of ETH required to purchase a given number of tokens.
     */
    function calculateEthReturnForTokens(uint256 tokenCount) external view returns (uint256) {
        return totalSupply().calculateSellReturn(tokenCount, INITIAL_PRICE, SLOPE, reserveBalance);
    }

    /* ============================================================================================== */
    /*                                        PRIVATE FUNCTIONS                                       */
    /* ============================================================================================== */

    /**
     * @notice Override of ERC20's `_update` function adding some custom layer checks.
     * @dev The custom checks are only applied in context of selling tokens.
     *
     *      By cheking `from != address(0) && to == address(this)` we ensure
     *      that will be applied only for {IERC20.transfer} / {IERC20.transferFrom}
     *      and to `address(this)` (token sells).
     */
    function _update(address from, address to, uint256 value) internal override {
        if (from != address(0) && to == address(this)) {
            if (value == 0) {
                revert IBondingSaleErrors.AmountMustBeGreaterThanZero();
            }
            value.enforceNotFraction();
        }

        super._update(from, to, value);
    }
}
