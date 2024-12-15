// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

/**
 * @notice Provides linear bonding curve utility functions.
 * @author Martin Ivanov
 */
library LinearBondingCurve {
    uint256 private constant SCALE = 1e18;

    error GasPriceExceedsLimit(uint256 currentGasPrice, uint256 maxGasPrice);
    error FractionalAmountNotSupported(uint256 providedAmount);

    /**
     * @notice Enforces that the transaction gas price does not exceed the maximum allowed value.
     * @dev Helps control gas costs and may deter certain front-running and sandwich attacks
     *      by restricting high gas price bids, but does not fully mitigate these attack vectors.
     */
    function enforceGasPrice(uint256 maxGasPrice) internal view {
        if (tx.gasprice > maxGasPrice) {
            revert GasPriceExceedsLimit(tx.gasprice, maxGasPrice);
        }
    }

    /**
     * @notice Checks that an ETH or token amount is not fractional.
     */
    function enforceNotFraction(uint256 amount) internal pure {
        if (amount % 1 ether != 0) {
            revert FractionalAmountNotSupported(amount);
        }
    }

    /**
     * @notice Calculates the cost in ETH for buying a given amount of tokens.
     * @param currentSupply The current total token supply in Wei.
     * @param tokenAmount The amount of tokens to buy in Wei.
     * @param initialPrice The initial price of the token.
     * @param slope The price increment per token.
     * @return finalCost The total cost in ETH for the specified amount of tokens.
     */
    function calculateBuyCost(
        uint256 currentSupply,
        uint256 tokenAmount,
        uint256 initialPrice,
        uint256 slope
    )
        internal
        pure
        returns (uint256 finalCost)
    {
        uint256 supply = currentSupply / SCALE;
        uint256 amount = tokenAmount / SCALE;

        // Calculate the start and end prices
        uint256 startPrice = initialPrice + (slope * supply);
        uint256 endPrice = startPrice + (slope * (amount - 1));

        // Apply the formula for cost calculation
        finalCost = ((startPrice + endPrice) * amount) / 2;
    }

    /**
     * @notice Calculates the ETH amount to return for selling a given amount of tokens.
     * @param currentSupply The current total token supply in Wei.
     * @param tokenAmount The amount of tokens to sell in Wei.
     * @param initialPrice The initial price of the token.
     * @param slope The price increment per token.
     * @return refund The total ETH refund for the specified amount of tokens.
     */
    function calculateSellReturn(
        uint256 currentSupply,
        uint256 tokenAmount,
        uint256 initialPrice,
        uint256 slope
    )
        internal
        pure
        returns (uint256 refund)
    {
        uint256 supply = currentSupply / SCALE;
        uint256 amount = tokenAmount / SCALE;

        // Calculate the start and end prices
        uint256 startPrice = initialPrice + (slope * (supply - amount));
        uint256 endPrice = startPrice + (slope * (amount - 1));

        // Apply the formula for refund calculation
        refund = ((startPrice + endPrice) * amount) / 2;
    }
}
