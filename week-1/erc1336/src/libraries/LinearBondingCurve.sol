// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

/**
 * @notice This library implements a linear bonding curve to calculate the price and return values
 * for tokens based on a bonding curve model.
 *
 * The library provides functions for calculating:
 *
 * - Cost of purchasing tokens;
 * - ETH return when selling tokens;
 * - Validation checks for gas price and fractional values.
 *
 * The bonding curve function used is linear:
 *
 *  `Price(n) = initialPrice + slope * n`
 *
 * @dev This library is for demonstration purposes only.
 */
library LinearBondingCurve {
    uint256 private constant SCALE = 1e18;

    error GasPriceExceedsLimit(uint256 currentGasPrice, uint256 maxGasPrice);
    error FractionalAmountNotSupported(uint256 providedAmount);
    error InsufficientReserveBalance();

    /**
     * @notice Ensures that the transaction gas price does not exceed the specified maximum.
     * @dev Restricts high gas price transactions, which can mitigate certain front-running attacks.
     *      However, it does not fully eliminate such risks.
     */
    function enforceGasPrice(uint256 maxGasPrice) internal view {
        if (tx.gasprice > maxGasPrice) {
            revert GasPriceExceedsLimit(tx.gasprice, maxGasPrice);
        }
    }

    /**
     * @notice Validates that an amount (ETH or tokens) is not fractional.
     * @dev Amounts must align with whole units in the `SCALE` defined system.
     */
    function enforceNotFraction(uint256 amount) internal pure {
        if (amount % SCALE != 0) {
            revert FractionalAmountNotSupported(amount);
        }
    }

    /**
     * @notice Calculates the cost of purchasing a specific number of tokens.
     */
    function calculateBuyCost(
        uint256 currentSupply,
        uint256 value,
        uint256 initialPrice,
        uint256 slope
    )
        internal
        pure
        returns (uint256 totalCost)
    {
        if (value == 0) {
            return 0;
        }
        uint256 startPrice = initialPrice + (slope * currentSupply / SCALE);
        uint256 endPrice = startPrice + (slope * (value - SCALE) / SCALE);

        totalCost = (startPrice + endPrice) * value / (2 * SCALE);
    }

    /**
     * @notice Calculates the ETH return when selling a specific number of tokens,
     * capped by the current reserve balance.
     */
    function calculateSellReturn(
        uint256 currentSupply,
        uint256 tokensToSell,
        uint256 initialPrice,
        uint256 slope,
        uint256 reserveBalance
    )
        internal
        pure
        returns (uint256 return_)
    {
        if (currentSupply == 0 || tokensToSell == 0) {
            return 0;
        }
        uint256 startPrice = initialPrice + (slope * (currentSupply - tokensToSell) / SCALE);
        uint256 endPrice = initialPrice + (slope * (currentSupply - SCALE) / SCALE);

        return_ = (startPrice + endPrice) * tokensToSell / (2 * SCALE);
        if (return_ > reserveBalance) {
            revert InsufficientReserveBalance();
        }
    }
}
