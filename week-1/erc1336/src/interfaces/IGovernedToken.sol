// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

/**
 * @dev Interface of the `GovernedToken` contract.
 */
interface IGovernedToken {
    /**
     * @notice Emitted when the contract is paused or unpaused.
     */
    event Paused(bool indexed paused);
    /**
     * @notice Emitted on an updated restriction.
     */
    event UpdatedRestriction(address indexed account, bytes1 indexed restriction);
    /**
     * @notice Emitted when a special transfer has been made.
     */
    event SupremeTransfer(address from, address to, uint256 amount);
}
