// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import {ERC1363Capped} from "@/contracts/ERC1363Capped.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Errors} from "@/interfaces/Errors.sol";

/**
 * @title SovereignToken
 * @notice This is a simple ERC1363Capped-compatible token with sanctions and "god-mode functionalities".
 * @author Martin Ivanov
 *
 * NOTE: Combines the 3rd and 4th points from the weekly tasks.
 */
contract SovereignToken is ERC1363Capped, Ownable2Step {
    mapping(address account => bool) private blacklist;

    /**
     * @notice Constructs the token using {ERC1363Capped} and {Ownable2Step} as
     * a foundation.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_
    )
        ERC1363Capped(name_, symbol_, maxSupply_)
        Ownable(msg.sender)
    {}

    /**
     * @notice Enables self-burning of `amount_` tokens.
     */
    function burn(uint256 amount_) external {
        _burn(msg.sender, amount_);
    }

    /**
     * @notice Mints `amount_` new token to `to_` account.
     */
    function mint(address to_, uint256 amount_) external onlyOwner {
        _mint(to_, amount_);
    }

    /* ==================================================== TRANSFERS =================================================== */

    /**
     * @notice Allow the owner to moves `amount_` of tokens from `from_` to `to_` account.
     * @dev Follows the FREI-PI pattern.
     */
    function specialModeTransfer(
        address from_,
        address to_,
        uint256 amount_
    )
        public
        onlyOwner
        returns (bool)
    {
        uint256 fromBalance = balanceOf(from_);
        _transfer(from_, to_, amount_);
        _afterTokenTransfer(fromBalance, balanceOf(from_));
        return true;
    }

    /**
     * @notice Inside of the OZ's ERC20 implementation the `_update` method is responsible for updating internal mappings.
     * This can be seen on:
     * `_transfer`,
     * `_mint`,
     * `_burn` methods.
     *
     * Here the methods overrides the ERC20 `_update` method adding an additional layer of logic.
     */
    function _update(address from_, address to_, uint256 value_) internal virtual override {
        if (blacklist[from_]) {
            revert Errors.BannedAccount(from_);
        }
        if (blacklist[to_]) {
            revert Errors.BannedAccount(to_);
        }

        super._update(from_, to_, value_);
    }

    /* ==================================================== BLACKLIST =================================================== */

    /**
     * @notice Allows the owner to blacklist an `_account` address.
     */
    function blacklistAddress(address _account) public onlyOwner {
        blacklist[_account] = true;
    }

    /**
     * @notice Allows the owner to whitelist again an `_account` address.
     */
    function whitelistAddress(address _account) public onlyOwner {
        blacklist[_account] = false;
    }

    /**
     * @notice Checks if an address `_account` is blacklisted.
     */
    function isBlacklisted(address _account) public view returns (bool) {
        return blacklist[_account];
    }

    /* ===================================================== PRIVATE ==================================================== */

    /**
     * @notice Checks if the `_from` and `_to` addresses are blacklisted.
     */
    function _beforeTokenTransfer(address _from, address _to) private view {
        if (blacklist[_from]) {
            revert Errors.BannedAccount(_from);
        }
        if (blacklist[_to]) {
            revert Errors.BannedAccount(_to);
        }
    }

    /**
     * @notice Checks if the `_afterBalance` is less than `_beforeBalance`. Used in {specialModeTransfer}.
     * @dev Adds a basic check to ensure the contract's invariant is maintained.
     */
    function _afterTokenTransfer(uint256 _beforeBalance, uint256 _afterBalance) private pure {
        if (_afterBalance >= _beforeBalance) {
            revert Errors.TransferFailed();
        }
    }
}
