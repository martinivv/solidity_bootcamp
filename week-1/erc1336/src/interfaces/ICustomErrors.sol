// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

/**
 * @notice Combines custom errors used in the `IGovernedToken`.
 */
interface IGovernedTokenErrors {
    /**
     * @notice Indicates a transfer failure due to a restricted account.
     */
    error RestrictedAccount(address account);
    /**
     * @notice Indicates a transfer failure due to a protocol invariant violation.
     */
    error TransferFailed();
    /**
     * @notice Indicates a transfer failure because the token is paused.
     */
    error TokenPaused();
}

/**
 * @notice Combines custom errors used in the `IBondingSale`.
 */
interface IBondingSaleErrors {
    /**
     * @notice Indicates that the function can only be called by a contract receiver.
     */
    error OnlyContractReceiver();
    /**
     * @notice Indicates that the provided amount must be greater than zero.
     */
    error AmountMustBeGreaterThanZero();
    /**
     * @notice Indicates that the token supply cap has been exceeded.
     */
    error TokenCapExceeded(uint256 attemptedSupply, uint256 maxCap);
    /**
     * @notice Indicates insufficient reserve balance for the operation.
     */
    error InsufficientReserveBalance(uint256 availableBalance, uint256 requiredBalance);
    /**
     * @notice Indicates a failure to transfer funds.
     */
    error TransferFailed();
}
