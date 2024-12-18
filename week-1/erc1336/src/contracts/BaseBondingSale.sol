// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {ERC1363Capped} from "@/contracts/ERC1363Capped.sol";
import {LinearBondingCurve} from "@/libraries/LinearBondingCurve.sol";
import {IBondingSale} from "@/interfaces/IBondingSale.sol";
import {IBondingSaleErrors} from "@/interfaces/ICustomErrors.sol";

/**
 * @notice Provides a foundation for the `BondingSale` contract.
 * @author Martin Ivanov
 */
abstract contract BaseBondingSale is ERC1363Capped {
    using LinearBondingCurve for uint256;

    uint256 public immutable INITIAL_PRICE;
    uint256 public immutable SLOPE;

    uint256 public reserveBalance;
    uint256 public maxGasPrice = 100 gwei;

    /**
     * @notice Modifier to check if the direct sender is the contract itself.
     * @dev Ensure that can only be called by the token contract after a transfer or approval.
     *      Only relevant for the ERC1363 callbacks {onTransferReceived} and {onApprovalReceived}.
     */
    modifier onlyContractReceiver() {
        if (msg.sender != address(this)) {
            revert IBondingSaleErrors.OnlyContractReceiver();
        }
        _;
    }

    /**
     * @notice Constructs the token using {ERC1363Capped} and initial "bonding token" parameters.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 _initialPrice,
        uint256 _slope
    )
        ERC1363Capped(name_, symbol_, maxSupply_)
    {
        INITIAL_PRICE = _initialPrice;
        SLOPE = _slope;
    }

    /**
     * @inheritdoc ERC1363Capped
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC1363Capped) returns (bool) {
        return interfaceId == type(IBondingSale).interfaceId || super.supportsInterface(interfaceId);
    }

    /* ============================================================================================== */
    /*                                       INTERNAL FUNCTIONS                                       */
    /* ============================================================================================== */

    /**
     * @notice Processes a buy by minting tokens for depositing ETH.
     */
    function _buy(address sender_, uint256 _depositAmount) internal {
        uint256 tokenAmount = totalSupply().calculateBuyCost(_depositAmount, INITIAL_PRICE, SLOPE);
        if (tokenAmount == 0) {
            revert IBondingSaleErrors.InsufficientEthSent(_depositAmount);
        }
        if (totalSupply() + tokenAmount > cap()) {
            revert IBondingSaleErrors.TokenCapExceeded();
        }

        reserveBalance += _depositAmount;
        emit IBondingSale.Mint(
            sender_, _depositAmount, tokenAmount, reserveBalance, totalSupply() + tokenAmount
        );
        _mint(sender_, tokenAmount);
    }

    /**
     * @notice Processes a sell by burning tokens and returning ETH to the seller.
     */
    function _sell(address spender, uint256 amount) internal {
        uint256 ethToReturn = totalSupply().calculateSellReturn(amount, INITIAL_PRICE, SLOPE, reserveBalance);

        reserveBalance -= ethToReturn;
        emit IBondingSale.Burn(amount, ethToReturn);
        _burn(address(this), amount);

        (bool ok,) = spender.call{value: ethToReturn}("");
        if (!ok) {
            revert IBondingSaleErrors.TransferFailed();
        }
    }
}
