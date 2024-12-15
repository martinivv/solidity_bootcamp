// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {BaseBondingSale} from "@/contracts/BaseBondingSale.sol";
import {LinearBondingCurve} from "@/libraries/LinearBondingCurve.sol";
import {IERC1363Receiver} from "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";
import {IERC1363Spender} from "@openzeppelin/contracts/interfaces/IERC1363Spender.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IBondingSale} from "@/interfaces/IBondingSale.sol";

/**
 * @notice Implements a token sale mechanism using a linear bonding curve.
 * @author Martin Ivanov
 */
contract BoundingSale is IBondingSale, Ownable, BaseBondingSale, IERC1363Receiver, IERC1363Spender {
    using LinearBondingCurve for uint256;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 initialPrice,
        uint256 slope
    )
        Ownable(msg.sender)
        BaseBondingSale(name, symbol, maxSupply, initialPrice, slope)
    {}

    /* ============================================================================================== */
    /*                                        PUBLIC FUNCTIONS                                        */
    /* ============================================================================================== */

    /**
     * @notice Allows users to accumulate tokens by sending ETH. The token price is
     *         determined by the bonding curve. Possible front-run mitigation is provided.
     *  @dev While enforceGasPrice has its advantages, it may sometimes need
     *       to be manually adjusted.
     */
    // solhint-disable-next-line no-complex-fallback
    receive() external payable {
        maxGasPrice.enforceGasPrice();
        _processBuy(msg.sender, msg.value);
    }

    /**
     * @notice Handles the sale of tokens through ERC1363 `transferAndCall`.
     *         Burns the tokens and returns ETH based on the bonding curve.
     */
    function onTransferReceived(
        address operator,
        address,
        uint256 value,
        bytes calldata
    )
        external
        override
        preventZeroTokenSale(value)
        isNotFractionOfToken(value)
        onlyContractReceiver
        returns (bytes4)
    {
        _processSale(operator, value);
        return IERC1363Receiver.onTransferReceived.selector;
    }

    /**
     * @notice Handles the sale of tokens through ERC1363 `approveAndCall`.
     *         Burns the tokens and returns ETH based on the bonding curve.
     */
    function onApprovalReceived(
        address owner,
        uint256 value,
        bytes calldata
    )
        external
        override
        preventZeroTokenSale(value)
        isNotFractionOfToken(value)
        onlyContractReceiver
        returns (bytes4)
    {
        transferFrom(owner, address(this), value);
        _processSale(owner, value);
        return IERC1363Spender.onApprovalReceived.selector;
    }

    /* ============================================================================================== */
    /*                                    ADMINISTRATIVE FUNCTIONS                                    */
    /* ============================================================================================== */

    function setMaxGasPrice(uint256 _gasPrice) external onlyOwner {
        maxGasPrice = _gasPrice;
        emit MaxGasPriceUpdated(_gasPrice);
    }

    /* ============================================================================================== */
    /*                                      VIEW FUNCTIONS                                            */
    /* ============================================================================================== */

    /**
     * @notice Returns the ETH cost to purchase a specific number of tokens.
     */
    function requiredEthToBuyToken(uint256 _tokenToBuy) external view returns (uint256) {
        return totalSupply().calculateBuyCost(_tokenToBuy, INITIAL_PRICE_, SLOPE_);
    }

    /**
     * @notice Returns the number of tokens that can be purchased with a given ETH amount.
     */
    function amountOfTokenEthCanBuy(uint256 _ethAmount) external view returns (uint256) {
        return totalSupply().calculateSellReturn(_ethAmount, INITIAL_PRICE_, SLOPE_);
    }
}
