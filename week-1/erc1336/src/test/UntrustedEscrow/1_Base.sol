// solhint-disable contract-name-camelcase
// solhint-disable func-name-mixedcase
// solhint-disable one-contract-per-file
// solhint-disable ordering

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {UntrustedEscrow} from "@/contracts/UntrustedEscrow.sol";
import {IUntrustedEscrowErrors} from "@/interfaces/ICustomErrors.sol";

/**
 * @notice Test the base functionality of the `UntrustedEscrow` contract.
 */
contract UntrustedEscrow_Base is Test {
    UntrustedEscrow internal escrow;
    IERC20 internal token;
    IERC20 internal feeToken;

    address internal owner;
    address internal buyer;
    address internal seller;
    address internal maliciousActor;

    uint256 internal initialBuyerBalance = 1000 ether;
    uint256 internal escrowAmount = 100 ether;
    uint256 internal constant RELEASE_DELAY = 3 days;

    event EscrowCreated(
        uint256 indexed escrowId,
        address indexed buyer,
        address indexed seller,
        address token,
        uint256 amount,
        uint256 releaseTime
    );

    event EscrowWithdrawn(uint256 indexed escrowId, address indexed seller, uint256 amount);

    function setUp() public {
        owner = vm.addr(99);
        vm.label(owner, "Owner");

        buyer = vm.addr(1);
        vm.label(buyer, "Buyer");
        vm.deal(buyer, initialBuyerBalance);

        seller = vm.addr(2);
        vm.label(seller, "Seller");

        maliciousActor = vm.addr(3);
        vm.label(maliciousActor, "Malicious Actor");

        // Setup regular test token
        token = IERC20(address(new TestToken()));
        vm.startPrank(buyer);
        TestToken(address(token)).mint(buyer, initialBuyerBalance);
        vm.stopPrank();

        // Setup fee-on-transfer token
        feeToken = IERC20(address(new FeeToken()));
        vm.startPrank(buyer);
        FeeToken(address(feeToken)).mint(buyer, initialBuyerBalance);
        vm.stopPrank();

        vm.prank(owner);
        escrow = new UntrustedEscrow();
    }

    /* ============================================================================================== */
    /*                                          CREATE ESCROW                                         */
    /* ============================================================================================== */

    function testCreateEscrowSuccess() public {
        vm.startPrank(buyer);
        token.approve(address(escrow), escrowAmount);

        vm.expectEmit(true, true, true, true);
        emit EscrowCreated(0, buyer, seller, address(token), escrowAmount, block.timestamp + RELEASE_DELAY);

        escrow.createEscrow(seller, token, escrowAmount);

        UntrustedEscrow.Escrow memory details = escrow.getEscrowDetails(0);

        assertEq(details.buyer, buyer);
        assertEq(details.seller, seller);
        assertEq(address(details.token), address(token));
        assertEq(details.amount, escrowAmount);
        assertEq(details.releaseTime, block.timestamp + RELEASE_DELAY);
        assertEq(token.balanceOf(address(escrow)), escrowAmount);
        assertEq(token.balanceOf(buyer), initialBuyerBalance - escrowAmount);
    }

    function testCreateMultipleEscrowsSuccess() public {
        vm.startPrank(buyer);
        token.approve(address(escrow), type(uint256).max);

        for (uint256 i = 0; i < 3; i++) {
            escrow.createEscrow(seller, token, escrowAmount);

            UntrustedEscrow.Escrow memory details = escrow.getEscrowDetails(i);
            assertEq(details.amount, escrowAmount);
            assertEq(details.buyer, buyer);
        }

        assertEq(token.balanceOf(address(escrow)), escrowAmount * 3);
        assertEq(token.balanceOf(buyer), initialBuyerBalance - (escrowAmount * 3));
    }

    function testCreateEscrowWithFeeToken() public {
        vm.startPrank(buyer);
        feeToken.approve(address(escrow), escrowAmount);

        escrow.createEscrow(seller, feeToken, escrowAmount);

        UntrustedEscrow.Escrow memory details = escrow.getEscrowDetails(0);
        // Fee token takes 10% fee, so actual amount should be 90% of escrowAmount
        assertEq(details.amount, (escrowAmount * 90) / 100);
    }

    function testCreateEscrowFailsInvalidSellerAddress() public {
        vm.startPrank(buyer);
        token.approve(address(escrow), escrowAmount);

        vm.expectRevert(IUntrustedEscrowErrors.InvalidSellerAddress.selector);
        escrow.createEscrow(address(0), token, escrowAmount);
    }

    function testCreateEscrowFailsInvalidAmount() public {
        vm.startPrank(buyer);
        token.approve(address(escrow), escrowAmount);

        vm.expectRevert(IUntrustedEscrowErrors.InvalidAmount.selector);
        escrow.createEscrow(seller, token, 0);
    }

    function testCreateEscrowFailsInsufficientAllowance() public {
        vm.startPrank(buyer);
        token.approve(address(escrow), escrowAmount - 1);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                address(escrow),
                escrowAmount - 1,
                escrowAmount
            )
        );
        escrow.createEscrow(seller, token, escrowAmount);
    }

    function testCreateEscrowFailsInsufficientBalance() public {
        vm.startPrank(buyer);
        token.approve(address(escrow), type(uint256).max);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                buyer,
                initialBuyerBalance,
                initialBuyerBalance + 1
            )
        );
        escrow.createEscrow(seller, token, initialBuyerBalance + 1);
    }

    /* ============================================================================================== */
    /*                                         WITHDRAW ESCROW                                        */
    /* ============================================================================================== */

    function testWithdrawEscrowSuccess() public {
        // Setup escrow
        vm.startPrank(buyer);
        token.approve(address(escrow), escrowAmount);
        escrow.createEscrow(seller, token, escrowAmount);
        vm.stopPrank();

        // Advance time and withdraw
        vm.warp(block.timestamp + RELEASE_DELAY);
        vm.startPrank(seller);

        vm.expectEmit(true, true, true, true);
        emit EscrowWithdrawn(0, seller, escrowAmount);

        escrow.withdrawEscrow(0);

        // Verify state changes
        assertEq(token.balanceOf(seller), escrowAmount);
        assertEq(token.balanceOf(address(escrow)), 0);

        UntrustedEscrow.Escrow memory details = escrow.getEscrowDetails(0);
        assertEq(details.amount, 0);
    }

    function testWithdrawEscrowWithFeeToken() public {
        // Setup escrow with fee token
        vm.startPrank(buyer);
        feeToken.approve(address(escrow), escrowAmount);
        escrow.createEscrow(seller, feeToken, escrowAmount);
        vm.stopPrank();

        uint256 actualAmount = (escrowAmount * 90) / 100; // 10% fee applied

        vm.warp(block.timestamp + RELEASE_DELAY);
        vm.startPrank(seller);
        escrow.withdrawEscrow(0);

        // Verify final balances (another 10% fee on transfer)
        assertEq(feeToken.balanceOf(seller), (actualAmount * 90) / 100);
        assertEq(feeToken.balanceOf(address(escrow)), 0);
    }

    function testWithdrawFailsBeforeDelay() public {
        vm.startPrank(buyer);
        token.approve(address(escrow), escrowAmount);
        escrow.createEscrow(seller, token, escrowAmount);
        vm.stopPrank();

        UntrustedEscrow.Escrow memory details = escrow.getEscrowDetails(0);
        uint256 releaseTime = details.releaseTime;

        vm.startPrank(seller);

        // Try just before release time
        vm.warp(releaseTime - 1);
        vm.expectRevert(IUntrustedEscrowErrors.ReleaseTimeNotReached.selector);
        escrow.withdrawEscrow(0);

        // Try at halfway point
        vm.warp(releaseTime - (RELEASE_DELAY / 2));
        vm.expectRevert(IUntrustedEscrowErrors.ReleaseTimeNotReached.selector);
        escrow.withdrawEscrow(0);

        // Try at start
        vm.warp(releaseTime - RELEASE_DELAY);
        vm.expectRevert(IUntrustedEscrowErrors.ReleaseTimeNotReached.selector);
        escrow.withdrawEscrow(0);

        vm.stopPrank();
    }

    function testWithdrawFailsUnauthorized() public {
        vm.startPrank(buyer);
        token.approve(address(escrow), escrowAmount);
        escrow.createEscrow(seller, token, escrowAmount);
        vm.stopPrank();

        vm.warp(block.timestamp + RELEASE_DELAY);

        // Try withdrawing from different unauthorized addresses
        address[] memory unauthorizedAddresses = new address[](3);
        unauthorizedAddresses[0] = buyer;
        unauthorizedAddresses[1] = maliciousActor;
        unauthorizedAddresses[2] = address(this);

        for (uint256 i = 0; i < unauthorizedAddresses.length; i++) {
            vm.startPrank(unauthorizedAddresses[i]);
            vm.expectRevert(IUntrustedEscrowErrors.Unauthorized.selector);
            escrow.withdrawEscrow(0);
            vm.stopPrank();
        }
    }

    function testWithdrawFailsAlreadyWithdrawn() public {
        vm.startPrank(buyer);
        token.approve(address(escrow), escrowAmount);
        escrow.createEscrow(seller, token, escrowAmount);
        vm.stopPrank();

        vm.warp(block.timestamp + RELEASE_DELAY);
        vm.startPrank(seller);

        escrow.withdrawEscrow(0);

        vm.expectRevert(IUntrustedEscrowErrors.AlreadyWithdrawn.selector);
        escrow.withdrawEscrow(0);
    }

    function testWithdrawFailsNonexistentEscrow() public {
        vm.startPrank(seller);
        vm.expectRevert(IUntrustedEscrowErrors.AlreadyWithdrawn.selector);
        escrow.withdrawEscrow(999);
    }

    /* ============================================================================================== */
    /*                                         VIEW FUNCTIONS                                         */
    /* ============================================================================================== */

    function testGetEscrowDetailsForNonexistentEscrow() public view {
        UntrustedEscrow.Escrow memory details = escrow.getEscrowDetails(999);
        assertEq(details.buyer, address(0));
        assertEq(details.seller, address(0));
        assertEq(address(details.token), address(0));
        assertEq(details.amount, 0);
        assertEq(details.releaseTime, 0);
    }

    function testGetEscrowDetailsAfterWithdrawal() public {
        vm.startPrank(buyer);
        token.approve(address(escrow), escrowAmount);
        escrow.createEscrow(seller, token, escrowAmount);
        vm.stopPrank();

        vm.warp(block.timestamp + RELEASE_DELAY);
        vm.prank(seller);
        escrow.withdrawEscrow(0);

        UntrustedEscrow.Escrow memory details = escrow.getEscrowDetails(0);
        assertEq(details.amount, 0);
        // Other fields should remain unchanged
        assertEq(details.buyer, buyer);
        assertEq(details.seller, seller);
        assertEq(address(details.token), address(token));
    }
}

contract TestToken is ERC20 {
    constructor() ERC20("Test Token", "TTK") {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

contract FeeToken is ERC20 {
    constructor() ERC20("Fee Token", "FEE") {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function _update(address from, address to, uint256 amount) internal virtual override {
        // Apply 10% fee on transfers, but not on burns (amount to address(0))
        if (to != address(0)) {
            uint256 feeAmount = (amount * 10) / 100;
            amount = amount - feeAmount;
            // Burn the fee
            super._update(from, address(0), feeAmount);
        }
        super._update(from, to, amount);
    }
}
