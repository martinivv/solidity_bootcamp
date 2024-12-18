// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

/**
 * @dev Interface of the `BoundingSale` contract.
 */
interface IBondingSale {
    /**
     * @notice Emitted when tokens are minted in exchange for an ETH deposit.
     */
    event Mint(
        address indexed sender,
        uint256 depositAmount,
        uint256 tokenAmount,
        uint256 reserveBalance,
        uint256 newTotalSupply
    );
    /**
     * @notice Emitted when tokens are burned in exchange for ETH, or when
     *         the buyback functionality has been activated.
     */
    event Burn(uint256 indexed amount, uint256 indexed ethToReturn);
    /**
     * @notice Emitted when the maximum gas price has been updated.
     */
    event MaxGasPriceUpdated(uint256 gasPrice);

    /* ============================================================================================== */
    /*                                             ERC1363                                            */
    /* ============================================================================================== */

    /**
     * @notice Called when tokens are transferred as part of the ERC1363's
     *         {transferAndCall / transferFromAndCall} functions.
     */
    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes calldata data
    )
        external
        returns (bytes4);

    /**
     * @notice Called when an approval is received through the ERC1363's
     *         {approveAndCall} function.
     */
    function onApprovalReceived(
        address owner,
        uint256 value,
        bytes calldata data
    )
        external
        returns (bytes4);
}
