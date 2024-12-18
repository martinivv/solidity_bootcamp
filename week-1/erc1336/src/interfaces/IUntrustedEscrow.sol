// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the `UntrustedEscrow` contract.
 */
interface IUntrustedEscrow {
    /**
     * @notice Struct to store escrow details.
     */
    struct Escrow {
        address buyer;
        address seller;
        IERC20 token;
        uint256 amount;
        uint256 releaseTime;
    }

    /* ============================================================================================== */
    /*                                             EVENTS                                             */
    /* ============================================================================================== */

    /**
     * @notice Event emitted when a new escrow is created.
     */
    event EscrowCreated(
        uint256 indexed escrowId,
        address indexed buyer,
        address indexed seller,
        address token,
        uint256 amount,
        uint256 releaseTime
    );
    /**
     * @notice Event emitted when escrow funds are withdrawn by the seller.
     */
    event EscrowWithdrawn(uint256 indexed escrowId, address indexed seller, uint256 amount);
}
