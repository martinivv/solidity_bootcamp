// solhint-disable one-contract-per-file
// solhint-disable no-console
// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase
// solhint-disable max-line-length
// solhint-disable ordering

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import {BaseLayout} from "./_layout.t.sol";
import {Errors} from "@/interfaces/Errors.sol";

contract SovereignTokenBasicsTest is BaseLayout {
    function setUp() public override {
        super.setUp();
    }

    function mintForAccount(address account_, uint256 amount_) internal {
        vm.prank(owner);
        MY_TOKEN_.mint(account_, amount_);
    }

    /* =================================================== TOKEN INIT =================================================== */

    function test_ChecksTokenName() public view {
        assertEq(keccak256(abi.encodePacked(MY_TOKEN_.name())), keccak256(abi.encodePacked(NAME)));
    }

    function test_ChecksTokenSymbol() public view {
        assertEq(keccak256(abi.encodePacked(MY_TOKEN_.symbol())), keccak256(abi.encodePacked(SYMBOL)));
    }

    function test_ChecksTokenCap() public view {
        assertEq(MY_TOKEN_.cap(), CAP);
    }

    function test_ChecksTokenOwner() public view {
        address _owner = MY_TOKEN_.owner();
        assertEq(_owner, owner);
    }

    /* ==================================================== BLACKLIST =================================================== */

    function test_BlacklistsUser() public {
        vm.prank(owner);
        MY_TOKEN_.blacklistAddress(bannedUser);
        assertTrue(MY_TOKEN_.isBlacklisted(bannedUser));
    }

    function test_WhitelistsUser() public {
        vm.startPrank(owner);
        MY_TOKEN_.blacklistAddress(bannedUser);
        MY_TOKEN_.whitelistAddress(bannedUser);
        vm.stopPrank();
        assertFalse(MY_TOKEN_.isBlacklisted(bannedUser));
    }

    /* ==================================================== TRANSFERS =================================================== */

    function test_MintsTokens() public {
        mintForAccount(owner, TEST_AMOUNT);
        assertEq(MY_TOKEN_.balanceOf(owner), TEST_AMOUNT);
    }

    function test_BurnsTokens() public {
        mintForAccount(owner, TEST_AMOUNT);
        vm.prank(owner);
        MY_TOKEN_.burn(TEST_AMOUNT);

        assertEq(MY_TOKEN_.balanceOf(owner), 0);
    }

    function test_TransfersTokens() public {
        mintForAccount(owner, TEST_AMOUNT);
        vm.prank(owner);
        MY_TOKEN_.transfer(user1, TEST_AMOUNT);
        assertEq(MY_TOKEN_.balanceOf(user1), TEST_AMOUNT);
    }

    function test_TransfersTokensFrom() public {
        mintForAccount(user1, TEST_AMOUNT);

        // 1. Approve
        vm.prank(user1);
        MY_TOKEN_.approve(owner, TEST_AMOUNT);

        // 2. Transfer
        vm.prank(owner);
        MY_TOKEN_.transferFrom(user1, owner, TEST_AMOUNT);

        assertEq(MY_TOKEN_.balanceOf(owner), TEST_AMOUNT);
        assertEq(MY_TOKEN_.balanceOf(user1), 0);
    }

    function test_SpecialModeTransfersTokens() public {
        mintForAccount(owner, TEST_AMOUNT);
        vm.startPrank(owner);
        MY_TOKEN_.blacklistAddress(bannedUser);

        bool ok = MY_TOKEN_.specialModeTransfer(owner, bannedUser, TEST_AMOUNT);
        vm.stopPrank();

        assertTrue(ok);
        assertEq(MY_TOKEN_.balanceOf(bannedUser), TEST_AMOUNT);
    }

    function test_TransferCannotBeFromBannedUser() public {
        mintForAccount(bannedUser, TEST_AMOUNT);

        // 1. Owner blacklists account
        vm.prank(owner);
        MY_TOKEN_.blacklistAddress(bannedUser);

        // 2. Transfer
        vm.startPrank(bannedUser);
        vm.expectRevert(abi.encodeWithSelector(Errors.BannedAccount.selector, bannedUser));
        MY_TOKEN_.transfer(user1, TEST_AMOUNT);
        vm.stopPrank();
    }

    function test_TransferCannotBeToBannedUser() public {
        mintForAccount(owner, TEST_AMOUNT);
        vm.prank(owner);
        MY_TOKEN_.blacklistAddress(bannedUser);
        vm.expectRevert(abi.encodeWithSelector(Errors.BannedAccount.selector, bannedUser));
        MY_TOKEN_.transfer(bannedUser, TEST_AMOUNT);
    }

    function test_TransferCannotBeFromBannedUserToBannedUser() public {
        mintForAccount(user1, TEST_AMOUNT);

        // 1. Owner blacklists the accounts
        vm.startPrank(owner);
        MY_TOKEN_.blacklistAddress(user1);
        MY_TOKEN_.blacklistAddress(bannedUser);
        vm.stopPrank();

        // 2. Transfer
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(Errors.BannedAccount.selector, user1));
        MY_TOKEN_.transfer(bannedUser, TEST_AMOUNT);
        vm.stopPrank();
    }

    function test_TransferFromCannotBeFromBannedUser() public {
        mintForAccount(bannedUser, TEST_AMOUNT);

        // 1. Approve
        vm.prank(bannedUser);
        MY_TOKEN_.approve(user1, TEST_AMOUNT);

        // 2. Owner blacklists account
        vm.prank(owner);
        MY_TOKEN_.blacklistAddress(bannedUser);

        // 3. Transfer
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(Errors.BannedAccount.selector, bannedUser));
        MY_TOKEN_.transferFrom(bannedUser, user1, TEST_AMOUNT);
        vm.stopPrank();
    }

    function test_TransferFromCannotBeToBannedUser() public {
        mintForAccount(user1, TEST_AMOUNT);

        // 1. Approve
        vm.prank(user1);
        MY_TOKEN_.approve(bannedUser, TEST_AMOUNT);

        // 2. Owner blacklists account
        vm.prank(owner);
        MY_TOKEN_.blacklistAddress(bannedUser);

        // 3. Transfer
        vm.startPrank(bannedUser);
        vm.expectRevert(abi.encodeWithSelector(Errors.BannedAccount.selector, bannedUser));
        MY_TOKEN_.transferFrom(user1, bannedUser, TEST_AMOUNT);
        vm.stopPrank();
    }

    function test_TransferFromCannotBeFromBannedUserToBannedUser() public {
        mintForAccount(user1, TEST_AMOUNT);

        // 1. Approve
        vm.prank(user1);
        MY_TOKEN_.approve(bannedUser, TEST_AMOUNT);

        // 2. Owner blacklists accounts
        vm.startPrank(owner);
        MY_TOKEN_.blacklistAddress(user1);
        MY_TOKEN_.blacklistAddress(bannedUser);
        vm.stopPrank();

        // 3. Transfer
        vm.startPrank(bannedUser);
        vm.expectRevert(abi.encodeWithSelector(Errors.BannedAccount.selector, user1));
        MY_TOKEN_.transferFrom(user1, bannedUser, TEST_AMOUNT);
        vm.stopPrank();
    }
}
