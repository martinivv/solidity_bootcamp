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
     * @notice Indicates that the ETH sent is insufficient the desired `tokenAmount`.
     */
    error InsufficientEthSent(uint256 ethSent);
    /**
     * @notice Indicates that the token supply cap has been exceeded.
     */
    error TokenCapExceeded();
    /**
     * @notice Indicates a failure to transfer funds.
     */
    error TransferFailed();
}

/**
 * @notice Combines custom errors used in the `IUntrustedEscrow`.
 */
interface IUntrustedEscrowErrors {
    /**
     * @notice Indicates a seller address provided is invalid (zero address).
     */
    error InvalidSellerAddress();
    /**
     * @notice Indicates the amount provided is invalid (zero or less).
     */
    error InvalidAmount();
    /**
     * @notice Indicates the token transfer failed or zero tokens were received.
     */
    error TransferFailed();
    /**
     * @notice Indicates the funds have already been withdrawn.
     */
    error AlreadyWithdrawn();
    /**
     * @notice Indicates the caller is unauthorized to perform the action.
     */
    error Unauthorized();
    /**
     * @notice Indicates the release time for the escrow has not been reached.
     */
    error ReleaseTimeNotReached();
}
