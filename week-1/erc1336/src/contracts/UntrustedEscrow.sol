// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IUntrustedEscrow} from "@/interfaces/IUntrustedEscrow.sol";
import {IUntrustedEscrowErrors} from "@/interfaces/ICustomErrors.sol";

/**
 * @notice A trust-minimized escrow contract where a buyer deposits ERC20 tokens,
 *         and the seller can withdraw them after a 3-day delay.
 * @author Martin Ivanov
 */
contract UntrustedEscrow is IUntrustedEscrow, ReentrancyGuardTransient {
    using SafeERC20 for IERC20;

    uint256 private constant RELEASE_DELAY = 3 days;

    mapping(uint256 => Escrow) private escrows;
    uint256 private _nextEscrowId;

    /* ============================================================================================== */
    /*                                        PUBLIC FUNCTIONS                                        */
    /* ============================================================================================== */

    /**
     * @notice Creates a new escrow with the specified seller, token and amount.
     * @dev Handles fee-on-transfer tokens by tracking actual received amount.
     * @dev Uses post-increment (_nextEscrowId++) to both get the current ID and increment
     *      for the next escrow in a single operation. The current value is assigned to
     *      escrowId first, then _nextEscrowId is incremented by 1.
     */
    function createEscrow(address _seller, IERC20 _token, uint256 _amount) external nonReentrant {
        if (_seller == address(0)) revert IUntrustedEscrowErrors.InvalidSellerAddress();
        if (_amount == 0) revert IUntrustedEscrowErrors.InvalidAmount();

        uint256 releaseTime = block.timestamp + RELEASE_DELAY;

        uint256 balanceBefore = _token.balanceOf(address(this));
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 balanceAfter = _token.balanceOf(address(this));

        uint256 actualAmount = balanceAfter - balanceBefore;
        if (actualAmount == 0) revert IUntrustedEscrowErrors.TransferFailed();

        uint256 escrowId = _nextEscrowId++;
        escrows[escrowId] = Escrow({
            buyer: msg.sender,
            seller: _seller,
            token: _token,
            amount: actualAmount,
            releaseTime: releaseTime
        });

        emit EscrowCreated(escrowId, msg.sender, _seller, address(_token), actualAmount, releaseTime);
    }

    /**
     * @notice Allows the seller to withdraw funds after the release time.
     */
    function withdrawEscrow(uint256 _escrowId) external nonReentrant {
        Escrow storage escrow = escrows[_escrowId];

        if (escrow.amount == 0) revert IUntrustedEscrowErrors.AlreadyWithdrawn();
        if (msg.sender != escrow.seller) revert IUntrustedEscrowErrors.Unauthorized();
        if (block.timestamp < escrow.releaseTime) revert IUntrustedEscrowErrors.ReleaseTimeNotReached();

        uint256 amount = escrow.amount;
        escrow.amount = 0;

        escrow.token.safeTransfer(escrow.seller, amount);
        emit EscrowWithdrawn(_escrowId, escrow.seller, amount);
    }

    /* ============================================================================================== */
    /*                                         VIEW FUNCTIONS                                         */
    /* ============================================================================================== */

    /**
     * @notice Returns the details of a specific escrow.
     */
    function getEscrowDetails(uint256 _escrowId) external view returns (Escrow memory escrow) {
        escrow = escrows[_escrowId];
    }
}
