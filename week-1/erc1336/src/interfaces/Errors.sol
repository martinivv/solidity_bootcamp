// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

/**
 * @dev Combines all custom errors used in the contracts.
 */
interface Errors {
    /**
     * @notice Indicates a failure within the {approve} part of a `approveAndCall` operation.
     */
    error ERC1363ApproveFailed(address spender, uint256 value);
    /**
     * @notice Indicates a failure within the {transfer} or {transferFrom} operations.
     */
    error BannedAccount(address account);
    /**
     * @notice Indicates a failure within the protocol invariant check.
     */
    error TransferFailed();
}
