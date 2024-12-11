// solhint-disable ordering
// solhint-disable no-inline-assembly

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import {ERC20Capped, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {ERC165, IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC1363} from "@openzeppelin/contracts/interfaces/IERC1363.sol";
import {
    ERC1363Utils,
    IERC1363Receiver,
    IERC1363Spender
} from "@openzeppelin/contracts/token/ERC20/utils/ERC1363Utils.sol";
import {Errors} from "@/interfaces/Errors.sol";

/**
 * @title ERC1363Capped
 * @notice Sets an `ERC1363Capped` interface extending `ERC20Capped`.
 * @author Martin Ivanov
 */
abstract contract ERC1363Capped is ERC20Capped, ERC165, IERC1363 {
    /**
     * @dev Sets the values for {name}, {symbol}, and {cap} as part the
     * `ERC20Capped` extension.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_
    )
        ERC20Capped(maxSupply_)
        ERC20(name_, symbol_)
    {}

    /**
     * @dev Checks if a given interface is supported.
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return (_interfaceId == type(IERC1363).interfaceId || super.supportsInterface(_interfaceId));
    }

    /**
     * @dev Transfers tokens and triggers a callback on the recipient side.
     */
    function transferAndCall(address _to, uint256 _amount) public virtual override returns (bool) {
        return transferAndCall(_to, _amount, "");
    }

    /**
     * @dev Variant of {transferAndCall} that accepts an additional `data` parameter with.
     *
     * NOTE: `checkOnERC1363TransferReceived` does not return boolean.
     */
    function transferAndCall(
        address to,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
        returns (bool)
    {
        transfer(to, amount);
        ERC1363Utils.checkOnERC1363TransferReceived(_msgSender(), _msgSender(), to, amount, data);
        return true;
    }

    /**
     * @dev Transfers tokens from a sender and triggers a callback on the recipient side.
     */
    function transferFromAndCall(
        address _from,
        address _to,
        uint256 _amount
    )
        public
        virtual
        override
        returns (bool)
    {
        return transferFromAndCall(_from, _to, _amount, "");
    }

    /**
     * @dev Variant of {transferFromAndCall} that accepts an additional `data` parameter with.
     *
     * NOTE: `checkOnERC1363TransferReceived` does not return boolean.
     */
    function transferFromAndCall(
        address from_,
        address to_,
        uint256 amount_,
        bytes memory data_
    )
        public
        virtual
        override
        returns (bool)
    {
        transferFrom(from_, to_, amount_);
        ERC1363Utils.checkOnERC1363TransferReceived(_msgSender(), from_, to_, amount_, data_);
        return true;
    }

    /**
     * @dev Approves a spender and triggers a callback on the spender side.
     */
    function approveAndCall(address _spender, uint256 _amount) public virtual override returns (bool) {
        return approveAndCall(_spender, _amount, "");
    }

    /**
     * @dev Variant of {approveAndCall} that accepts an additional `data` parameter.
     *
     * NOTE: `checkOnERC1363ApprovalReceived` does not return boolean.
     */
    function approveAndCall(
        address spender_,
        uint256 amount_,
        bytes memory data
    )
        public
        virtual
        override
        returns (bool)
    {
        if (!approve(spender_, amount_)) {
            revert Errors.ERC1363ApproveFailed(spender_, amount_);
        }
        ERC1363Utils.checkOnERC1363ApprovalReceived(_msgSender(), spender_, amount_, data);
        return true;
    }
}
