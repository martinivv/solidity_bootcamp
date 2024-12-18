// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

import {ERC1363Capped} from "@/contracts/ERC1363Capped.sol";
import {IGovernedToken} from "@/interfaces/IGovernedToken.sol";
import {IGovernedTokenErrors} from "@/interfaces/ICustomErrors.sol";

/**
 * @notice This is a simple ERC1363Capped-compatible token with sanctions and
 *         supreme mode transfer functionality.
 * @author Martin Ivanov
 *
 * NOTE: Combines the 3rd and 4th tasks from the week.
 */
contract GovernedToken is IGovernedToken, Ownable2Step, ERC1363Capped {
    // Bits representation:
    bytes1 public constant SEND_RESTRICTION = 0x01; // 0b\\ 00_00_00_01
    bytes1 public constant RECEIVE_RESTRICTION = 0x02; // 0b\\ 00_00_00_10

    mapping(address account => bytes1) public restrictions;

    bool public paused;

    /**
     * @notice Constructs the token using {ERC1363Capped} and {Ownable2Step} as a foundation.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_
    )
        Ownable(msg.sender)
        ERC1363Capped(name_, symbol_, maxSupply_)
    {
        _mint(msg.sender, 100_000_000 * 10 ** decimals());
    }

    /**
     * @inheritdoc ERC1363Capped
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC1363Capped) returns (bool) {
        return interfaceId == type(IGovernedToken).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Enables self-burning of `amount_` tokens.
     */
    // solhint-disable-next-line ordering
    function burn(uint256 amount_) external {
        _burn(msg.sender, amount_);
    }

    /**
     * @notice Mints `amount_` new token to `to_` account.
     */
    function mint(address to_, uint256 amount_) external onlyOwner {
        _mint(to_, amount_);
    }

    /* ============================================================================================== */
    /*                                    ADMINISTRATIVE FUNCTIONS                                    */
    /* ============================================================================================== */

    /**
     * @notice Allows the owner to pause or unpause the token.
     */
    function togglePause(bool _paused) external onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    /**
     * @notice Updates restrictions for a given account.
     * @dev Using the bitwise OR (|) a new restriction is added without overwriting previous one (if added).
     *
     * Example:
     * - Initially, `restrictions[account]` = 0x00, 0b\\ 00_00_00_00;
     * - `updateRestriction(account, 0x01)` = 0x01, 0b\\ 00_00_00_01;
     * - `updateRestriction(account, 0x02)` = 0x03, 0b\\ 00_00_00_11.
     */
    function updateRestriction(address account, bytes1 restriction) external onlyOwner {
        restrictions[account] |= restriction;
        emit UpdatedRestriction(account, restriction);
    }

    /**
     * @notice Checks if an address has a specific restriction.
     *         Returns `true` if the address has the restriction, `false` otherwise.
     * @dev Uses a bitwise AND (&) operator to determine whether the specified restriction flag is active.
     *
     * Example:
     * - `restrictions[account]` = 0x03, 0b\\ 00_00_00_11;
     * - `hasRestriction(account, 0x01)` = true;
     * - `hasRestriction(account, 0x02)` = true;
     * - `hasRestriction(account, 0x04)` = false.
     */
    function hasRestriction(address account, bytes1 restriction) public view returns (bool) {
        return (restrictions[account] & restriction) == restriction;
    }

    /* ============================================================================================== */
    /*                                       TRANSFER FUNCTIONS                                       */
    /* ============================================================================================== */

    /**
     * @notice Allow the owner to move `amount_` of tokens from the `from_` account to the
     *         `to_` account, regardless of whether the token is paused or if one or both accounts are blacklisted.
     * @dev Follows the FREI-PI pattern.
     */
    // solhint-disable-next-line ordering
    function supremeTransfer(address from_, address to_, uint256 amount_) external onlyOwner returns (bool) {
        uint256 initBalance = balanceOf(from_);
        super._update(from_, to_, amount_);
        _afterTokenTransfer(initBalance, balanceOf(from_));
        emit SupremeTransfer(from_, to_, amount_);
        return true;
    }

    /**
     * @notice Inside of the OZ's ERC20 implementation the `_update` method is responsible for updating internal mappings.
     * This can be seen on:
     *
     * - `_transfer`,
     * - `_mint`,
     * - `_burn` methods.
     *
     * Here the method overrides the ERC20 `_update` method adding an additional layer of logic.
     */
    function _update(address from_, address to_, uint256 value_) internal override {
        if (paused) {
            revert IGovernedTokenErrors.TokenPaused();
        }
        if (hasRestriction(from_, SEND_RESTRICTION)) {
            revert IGovernedTokenErrors.RestrictedAccount(from_);
        }
        if (hasRestriction(to_, RECEIVE_RESTRICTION)) {
            revert IGovernedTokenErrors.RestrictedAccount(to_);
        }

        super._update(from_, to_, value_);
    }

    /* ============================================================================================== */
    /*                                        PRIVATE FUNCTIONS                                       */
    /* ============================================================================================== */

    /**
     * @notice Ensure that `_after` balance is lower than `_before` balance. Used in {supremeTransfer}.
     * @dev Adds a basic check to ensure the contract's invariant is maintained. Allows zero amount transfers.
     */
    function _afterTokenTransfer(uint256 _before, uint256 _after) private pure {
        if (_after > _before) {
            revert IGovernedTokenErrors.TransferFailed();
        }
    }
}
