// solhint-disable contract-name-camelcase
// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase
// solhint-disable max-line-length
// solhint-disable ordering

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {IERC1363} from "@openzeppelin/contracts/interfaces/IERC1363.sol";
import {BaseLayout} from "@/test/GovernedToken/_layout.t.sol";
import {IGovernedToken} from "@/interfaces/IGovernedToken.sol";
import {IGovernedTokenErrors} from "@/interfaces/ICustomErrors.sol";

/**
 * @notice Test the base functionality of the `GovernedToken` contract.
 */
contract GovernedToken_Base is BaseLayout {
    function setUp() public override {
        super.setUp();
    }

    function mintForAccount(address account_, uint256 amount_) internal {
        vm.prank(owner);
        token.mint(account_, amount_);
    }

    /* ============================================================================================== */
    /*                                      TOKEN INITIALIZATION                                      */
    /* ============================================================================================== */

    function test_TokenName() public view {
        assertEq(keccak256(abi.encodePacked(token.name())), keccak256(abi.encodePacked(NAME)));
    }

    function test_TokenSymbol() public view {
        assertEq(keccak256(abi.encodePacked(token.symbol())), keccak256(abi.encodePacked(SYMBOL)));
    }

    function test_TokenCap() public view {
        assertEq(token.cap(), CAP);
    }

    function test_TokenOwner() public view {
        address _owner = token.owner();
        assertEq(_owner, owner);
    }

    function test_OwnerBalance() public view {
        uint256 ownerBalance = token.balanceOf(owner);
        assertEq(ownerBalance, INITIAL_SUPPLY);
    }

    function test_TokenTotalSupply() public view {
        uint256 totalSupply = token.totalSupply();
        assertEq(totalSupply, INITIAL_SUPPLY);
    }

    /* ============================================================================================== */
    /*                                       TRANSFER FUNCTIONS                                       */
    /* ============================================================================================== */

    function test_Mint() public {
        vm.prank(owner);
        token.mint(user1, TEST_AMOUNT);
        assertEq(token.balanceOf(user1), TEST_AMOUNT);
    }

    function test_Burn() public {
        mintForAccount(user1, TEST_AMOUNT);
        vm.prank(user1);
        token.burn(TEST_AMOUNT);

        assertEq(token.balanceOf(user1), 0);
    }

    function test_Transfer() public {
        vm.prank(owner);
        token.transfer(user1, TEST_AMOUNT);
        assertEq(token.balanceOf(user1), TEST_AMOUNT);
    }

    function test_TransferFrom() public {
        mintForAccount(user1, TEST_AMOUNT);

        // Approve
        vm.prank(user1);
        token.approve(user2, TEST_AMOUNT);

        // Transfer
        vm.prank(user2);
        token.transferFrom(user1, user2, TEST_AMOUNT);

        assertEq(token.balanceOf(user2), TEST_AMOUNT);
        assertEq(token.balanceOf(user1), 0);
    }

    function test_SupremeTransfer() public {
        vm.startPrank(owner);
        token.updateRestriction(restrictedUser, token.RECEIVE_RESTRICTION());

        bool ok = token.supremeTransfer(owner, restrictedUser, TEST_AMOUNT);
        vm.stopPrank();

        assertTrue(ok);
        assertEq(token.balanceOf(restrictedUser), TEST_AMOUNT);
    }

    function test_SupremeTransfers_EmitEvent() public {
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, false);
        emit IGovernedToken.SupremeTransfer(owner, user1, TEST_AMOUNT);
        token.supremeTransfer(owner, user1, TEST_AMOUNT);
        vm.stopPrank();
    }

    function test_Transfer_CannotBeFromRestrictedUser() public {
        mintForAccount(restrictedUser, TEST_AMOUNT);

        // Owner restricts account
        vm.startPrank(owner);
        token.updateRestriction(restrictedUser, token.SEND_RESTRICTION());
        vm.stopPrank();

        // Transfer
        vm.startPrank(restrictedUser);
        vm.expectRevert(
            abi.encodeWithSelector(IGovernedTokenErrors.RestrictedAccount.selector, restrictedUser)
        );
        token.transfer(user1, TEST_AMOUNT);
        vm.stopPrank();
    }

    function test_Transfer_CannotBeToRestrictedUser() public {
        vm.startPrank(owner);
        token.updateRestriction(restrictedUser, token.RECEIVE_RESTRICTION());
        vm.stopPrank();
        vm.expectRevert(
            abi.encodeWithSelector(IGovernedTokenErrors.RestrictedAccount.selector, restrictedUser)
        );
        token.transfer(restrictedUser, TEST_AMOUNT);
    }

    function test_Transfer_CannotBeFromRestrictedToRestricted() public {
        mintForAccount(user1, TEST_AMOUNT);

        // Owner restricts the accounts
        vm.startPrank(owner);
        token.updateRestriction(user1, token.SEND_RESTRICTION());
        token.updateRestriction(restrictedUser, token.RECEIVE_RESTRICTION());
        vm.stopPrank();

        // Transfer
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IGovernedTokenErrors.RestrictedAccount.selector, user1));
        token.transfer(restrictedUser, TEST_AMOUNT);
        vm.stopPrank();
    }

    function test_TransferFrom_CannotBeFromRestricted() public {
        mintForAccount(restrictedUser, TEST_AMOUNT);

        // Approve
        vm.prank(restrictedUser);
        token.approve(user1, TEST_AMOUNT);

        // Owner restricts account
        vm.startPrank(owner);
        token.updateRestriction(restrictedUser, token.SEND_RESTRICTION());
        vm.stopPrank();

        // Transfer
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(IGovernedTokenErrors.RestrictedAccount.selector, restrictedUser)
        );
        token.transferFrom(restrictedUser, user1, TEST_AMOUNT);
        vm.stopPrank();
    }

    function test_TransferFrom_CannotBeToRestricted() public {
        mintForAccount(user1, TEST_AMOUNT);

        // Approve
        vm.prank(user1);
        token.approve(restrictedUser, TEST_AMOUNT);

        // Owner restricts account

        vm.startPrank(owner);
        token.updateRestriction(restrictedUser, token.RECEIVE_RESTRICTION());
        vm.stopPrank();

        // Transfer
        vm.startPrank(restrictedUser);
        vm.expectRevert(
            abi.encodeWithSelector(IGovernedTokenErrors.RestrictedAccount.selector, restrictedUser)
        );
        token.transferFrom(user1, restrictedUser, TEST_AMOUNT);
        vm.stopPrank();
    }

    function test_TransferFrom_CannotBeFromRestrictedToRestricted() public {
        mintForAccount(user1, TEST_AMOUNT);

        // Approve
        vm.prank(user1);
        token.approve(restrictedUser, TEST_AMOUNT);

        // Owner restricts accounts
        vm.startPrank(owner);
        token.updateRestriction(restrictedUser, token.SEND_RESTRICTION());
        token.updateRestriction(restrictedUser, token.RECEIVE_RESTRICTION());
        vm.stopPrank();

        // Transfer
        vm.startPrank(restrictedUser);
        vm.expectRevert(
            abi.encodeWithSelector(IGovernedTokenErrors.RestrictedAccount.selector, restrictedUser)
        );
        token.transferFrom(user1, restrictedUser, TEST_AMOUNT);
        vm.stopPrank();
    }

    function test_ExceedsMaxCap() public {
        uint256 mintAmount = CAP - INITIAL_SUPPLY + 1;
        vm.prank(owner);
        vm.expectRevert();
        token.mint(user1, mintAmount);
    }

    /* ============================================================================================== */
    /*                                    ADMINISTRATIVE FUNCTIONS                                    */
    /* ============================================================================================== */

    function test_SupportsInterface_IGovernedToken() public view {
        bytes4 interfaceId = type(IERC1363).interfaceId;
        assertTrue(token.supportsInterface(interfaceId));
    }

    function test_SupportsInterface_Invalid() public view {
        bytes4 interfaceId = bytes4(keccak256("invalid()"));
        assertFalse(token.supportsInterface(interfaceId));
    }

    function test_TransferOwnership() public {
        // Initiate
        vm.prank(owner);
        token.transferOwnership(user1);

        // Accept
        vm.prank(user1);
        token.acceptOwnership();

        assertEq(token.owner(), user1);
    }

    function test_PauseAndEmitEvent() public {
        vm.startPrank(owner);
        vm.expectEmit(true, false, false, false);
        emit IGovernedToken.Paused(true);
        token.togglePause(true);
        vm.stopPrank();

        assertTrue(token.paused());
    }

    function test_UnpauseAndEmitEvent() public {
        vm.startPrank(owner);
        vm.expectEmit(true, false, false, false);
        emit IGovernedToken.Paused(false);
        token.togglePause(false);
        vm.stopPrank();

        assertFalse(token.paused());
    }

    function test_WhilePaused_MintingIsDisabled() public {
        vm.startPrank(owner);
        token.togglePause(true);
        vm.expectRevert(abi.encodeWithSelector(IGovernedTokenErrors.TokenPaused.selector));
        token.mint(user1, TEST_AMOUNT);
        vm.stopPrank();
    }

    function test_WhilePaused_TransferIsDisabled() public {
        vm.prank(owner);
        token.togglePause(true);
        vm.expectRevert(abi.encodeWithSelector(IGovernedTokenErrors.TokenPaused.selector));
        token.transfer(user1, TEST_AMOUNT);
    }

    function test_WhilePaused_TransferFromIsDisabled() public {
        vm.prank(user1);
        token.approve(owner, TEST_AMOUNT);

        vm.startPrank(owner);
        token.togglePause(true);
        vm.expectRevert(abi.encodeWithSelector(IGovernedTokenErrors.TokenPaused.selector));
        token.transferFrom(user1, owner, TEST_AMOUNT);
        vm.stopPrank();
    }

    function test_WhilePaused_SupremeTransfersPass() public {
        vm.startPrank(owner);
        token.togglePause(true);
        bool ok = token.supremeTransfer(owner, user1, TEST_AMOUNT);
        vm.stopPrank();

        assertTrue(ok);
        assertEq(token.balanceOf(user1), TEST_AMOUNT);
    }

    function test_UpdateRestriction_Send() public {
        vm.startPrank(owner);
        token.updateRestriction(restrictedUser, token.SEND_RESTRICTION());
        vm.stopPrank();
        assertTrue(token.hasRestriction(restrictedUser, token.SEND_RESTRICTION()));
        assertFalse(token.hasRestriction(restrictedUser, token.RECEIVE_RESTRICTION()));
    }

    function test_UpdateRestriction_Receive() public {
        vm.startPrank(owner);
        token.updateRestriction(restrictedUser, token.RECEIVE_RESTRICTION());
        vm.stopPrank();
        assertTrue(token.hasRestriction(restrictedUser, token.RECEIVE_RESTRICTION()));
        assertFalse(token.hasRestriction(restrictedUser, token.SEND_RESTRICTION()));
    }

    function test_UpdateRestriction_Both() public {
        vm.startPrank(owner);
        token.updateRestriction(restrictedUser, token.SEND_RESTRICTION());
        token.updateRestriction(restrictedUser, token.RECEIVE_RESTRICTION());
        vm.stopPrank();
        assertTrue(token.hasRestriction(restrictedUser, token.SEND_RESTRICTION()));
        assertTrue(token.hasRestriction(restrictedUser, token.RECEIVE_RESTRICTION()));
    }

    function test_UpdateRestriction_Whitelist() public {
        vm.prank(owner);
        token.updateRestriction(restrictedUser, 0x00);
        assertFalse(token.hasRestriction(restrictedUser, token.SEND_RESTRICTION()));
        assertFalse(token.hasRestriction(restrictedUser, token.RECEIVE_RESTRICTION()));
    }
}
