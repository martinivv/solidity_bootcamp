// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

import {ERC1363Capped} from "@/contracts/ERC1363Capped.sol";
import {LinearBondingCurve} from "@/libraries/LinearBondingCurve.sol";
import {IBondingSale} from "@/interfaces/IBondingSale.sol";
import {IBondingSaleErrors} from "@/interfaces/ICustomErrors.sol";

/**
 * @notice Abstract contract providing foundation for the `BondingSale` contract.
 * @author Martin Ivanov
 */
abstract contract BaseBondingSale is ERC1363Capped, ReentrancyGuardTransient {
    using LinearBondingCurve for uint256;

    uint256 public immutable INITIAL_PRICE_;
    uint256 public immutable SLOPE_;

    uint256 public reserveBalance;
    uint256 public maxGasPrice = 100 gwei;

    /**
     * @notice Modifier to check if the direct sender is the contract itself.
     */
    modifier onlyContractReceiver() {
        if (msg.sender != address(this)) {
            revert IBondingSaleErrors.OnlyContractReceiver();
        }
        _;
    }

    /**
     * @notice A modifier that checks if the `amount` is a whole number.
     */
    modifier isNotFractionOfToken(uint256 amount) {
        amount.enforceNotFraction();
        _;
    }

    /**
     * @notice A modifier that checks if the amount is greater than 0.
     */
    modifier preventZeroTokenSale(uint256 amount) {
        if (amount == 0) {
            revert IBondingSaleErrors.AmountMustBeGreaterThanZero();
        }
        _;
    }

    /**
     * @notice Constructs the token using {ERC1363Capped} and initial "bounding token" parameters.
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
        INITIAL_PRICE_ = _initialPrice;
        SLOPE_ = _slope;
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
    function _processBuy(address sender_, uint256 _amount) internal nonReentrant {
        uint256 depositAmount = _amount;
        if (depositAmount == 0) {
            revert IBondingSaleErrors.AmountMustBeGreaterThanZero();
        }

        uint256 tokenAmount = totalSupply().calculateBuyCost(depositAmount, INITIAL_PRICE_, SLOPE_);
        if (totalSupply() + tokenAmount > cap()) {
            revert IBondingSaleErrors.TokenCapExceeded(totalSupply() + tokenAmount, cap());
        }

        reserveBalance += depositAmount;
        emit IBondingSale.Mint(
            sender_, depositAmount, tokenAmount, reserveBalance, totalSupply() + tokenAmount
        );
        _mint(sender_, tokenAmount);
    }

    /**
     * @notice Processes a sale by burning tokens and returning ETH to the seller.
     */
    function _processSale(address spender, uint256 amount) internal nonReentrant {
        uint256 ethToReturn = totalSupply().calculateSellReturn(amount, INITIAL_PRICE_, SLOPE_);
        if (reserveBalance < ethToReturn) {
            revert IBondingSaleErrors.InsufficientReserveBalance(reserveBalance, ethToReturn);
        }

        reserveBalance -= ethToReturn;
        emit IBondingSale.Burn(amount, ethToReturn);
        _burn(address(this), amount);
        (bool ok,) = spender.call{value: ethToReturn}("");
        if (!ok) {
            revert IBondingSaleErrors.TransferFailed();
        }
    }
}
