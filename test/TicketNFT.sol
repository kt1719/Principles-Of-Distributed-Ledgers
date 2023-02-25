// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../lib/forge-std/src/Test.sol";
import "../src/contracts/TicketNFT.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/contracts/PrimaryMarket.sol";

contract BaseTicketNFTTest is Test {
    // Define events
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed ticketID
    );

    event Approval(
        address indexed holder,
        address indexed approved,
        uint256 indexed ticketID
    );

    // Define the variables
    TicketNFT ticketNFT; //address = undefined
    PrimaryMarket primaryMarket;
    PurchaseToken purchaseToken;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    uint256 public nftPrice = 100e18;

    // Define the functions

    function setUp() public {
        purchaseToken = new PurchaseToken();
        primaryMarket = new PrimaryMarket(purchaseToken, ticketNFT);
        ticketNFT = new TicketNFT(primaryMarket);
        primaryMarket.changeTicketNFT(ticketNFT); // used to get over dependency cycle address referencing
    }

    function _mintNFT(address owner, string memory name) internal {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(owner, name);
    }
}

// Define test contract
contract TicketNFTTest is BaseTicketNFTTest {
    function testMint() public {
        vm.prank(address(primaryMarket));
        vm.expectEmit(true, true, true, false);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");
        assertEq(ticketNFT.isExpiredOrUsed(1), false);
        assertEq(ticketNFT.expiryOf(1), block.timestamp + 10 days);
        assertEq(ticketNFT.totalSupply(), 1);
        assertEq(purchaseToken.balanceOf(alice), 0);
    }

    function testMintNotPrimaryMarket() public {
        vm.prank(address(alice));
        vm.expectRevert("caller must be primary market");
        ticketNFT.mint(alice, "alice");
        assertEq(ticketNFT.totalSupply(), 0);
    }

    function testBalanceOf() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
    }

    function testBalancesOf() public {
        _mintNFT(alice, "alice");
        _mintNFT(alice, "alice");
        _mintNFT(bob, "bob");
        assertEq(ticketNFT.balanceOf(alice), 2);
        assertEq(ticketNFT.balanceOf(bob), 1);
        assertEq(ticketNFT.balanceOf(charlie), 0);
    }

    function testHolderOf() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.holderOf(1), alice);
    }

    function testHolderOfNoID() public {
        _mintNFT(alice, "alice");
        vm.expectRevert("ticketID does not exist");
        ticketNFT.holderOf(2);
    }

    function testHolderNameOf() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.holderNameOf(1), "alice");
    }

    function testHolderNameOfNoID() public {
        _mintNFT(alice, "alice");
        vm.expectRevert("ticketID does not exist");
        ticketNFT.holderNameOf(2);
    }

    function testIsExpiredOrUsedFalse() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.isExpiredOrUsed(1), false);
    }

    function testIsExpiredOrUsedTrue() public {
        _mintNFT(alice, "alice");
        vm.prank(address(this));
        ticketNFT.setUsed(1);
        assertEq(ticketNFT.isExpiredOrUsed(1), true);
    }

    function testIsExpiredOrUsedTime() public {
        _mintNFT(alice, "alice");
        vm.prank(address(this));
        vm.warp(block.timestamp + 10 days + 1 seconds);
        assertEq(ticketNFT.isExpiredOrUsed(1), true);
    }

    function testTransferFromApproved() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");

        vm.prank(alice);
        vm.expectEmit(true, true, true, false);
        emit Approval(alice, bob, 1);
        ticketNFT.approve(bob, 1);
        assertEq(ticketNFT.getApproved(1), bob);

        vm.prank(bob);
        vm.expectEmit(true, true, true, false);
        emit Transfer(alice, bob, 1);
        vm.expectEmit(true, true, true, false);
        emit Approval(bob, address(0), 1);
        ticketNFT.transferFrom(alice, bob, 1);
        assertEq(ticketNFT.balanceOf(alice), 0);
        assertEq(ticketNFT.balanceOf(bob), 1);
        assertEq(ticketNFT.holderOf(1), bob);
        assertEq(ticketNFT.holderNameOf(1), "alice");
        assertEq(purchaseToken.balanceOf(alice), 0);
    }

    function testTransferFromOwner() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");

        vm.prank(alice);
        vm.expectEmit(true, true, true, false);
        emit Transfer(alice, bob, 1);
        vm.expectEmit(true, true, true, false);
        emit Approval(bob, address(0), 1);
        ticketNFT.transferFrom(alice, bob, 1);
        assertEq(ticketNFT.balanceOf(alice), 0);
        assertEq(ticketNFT.balanceOf(bob), 1);
        assertEq(ticketNFT.holderOf(1), bob);
        assertEq(ticketNFT.holderNameOf(1), "alice");
        assertEq(purchaseToken.balanceOf(alice), 0);
    }

    function testTransferFromNotOwner() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");

        vm.prank(alice);
        vm.expectRevert("from must be the holder of the ticket");
        ticketNFT.transferFrom(charlie, bob, 1);
    }

    function testTransferFromNotApproved() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");

        vm.prank(bob);
        vm.expectRevert("caller must be the holder of the ticket or the approved address for it");
        ticketNFT.transferFrom(alice, bob, 1);
    }

    function testTransferFromZeroAddress() public {
        _mintNFT(address(0), "address 0");
        assertEq(ticketNFT.balanceOf(address(0)), 1);
        assertEq(ticketNFT.holderOf(1), address(0));
        assertEq(ticketNFT.holderNameOf(1), "address 0");

        vm.prank(address(0));
        vm.expectRevert("transfer cannot be from the zero address");
        ticketNFT.transferFrom(address(0), alice, 1);
    }

    function testTransferToZeroAddress() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");

        vm.prank(alice);
        vm.expectRevert("transfer cannot be to the zero address");
        ticketNFT.transferFrom(alice, address(0), 1);
    }

    function testApprove() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");

        vm.prank(alice);
        vm.expectEmit(true, true, true, false);
        emit Approval(alice, bob, 1);
        ticketNFT.approve(bob, 1);
        assertEq(ticketNFT.getApproved(1), bob);
    }

    function testApproveUnauthorized() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");

        vm.prank(bob);
        vm.expectRevert("caller must be the holder of the ticket");
        ticketNFT.approve(bob, 1);
    }

    function testApproveNoID() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");

        vm.prank(alice);
        vm.expectRevert("ticketID does not exist");
        ticketNFT.approve(bob, 2);
    }

    function testGetApproved() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");

        vm.prank(alice);
        vm.expectEmit(true, true, true, false);
        emit Approval(alice, bob, 1);
        ticketNFT.approve(bob, 1);
        assertEq(ticketNFT.getApproved(1), bob);
    }

    function testGetApprovedNoID() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");

        vm.prank(alice);
        vm.expectRevert("ticketID does not exist");
        ticketNFT.getApproved(2);
    }

    function testUpdateHolderName() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");

        vm.prank(alice);
        ticketNFT.updateHolderName(1, "bob");
        assertEq(ticketNFT.holderNameOf(1), "bob");
    }

    function testUpdateHolderNameNoID() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");

        vm.prank(alice);
        vm.expectRevert("ticketID does not exist");
        ticketNFT.updateHolderName(2, "bob");
    }

    function testUpdateHolderNameUnauthorized() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");

        vm.prank(bob);
        vm.expectRevert("caller must be the holder of the ticket");
        ticketNFT.updateHolderName(1, "bob");
    }

    function testSetUsed() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");

        vm.prank(address(this));
        ticketNFT.setUsed(1);
        assertEq(ticketNFT.isExpiredOrUsed(1), true);
    }

    function testSetUsedNoID() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");

        vm.prank(address(this));
        vm.expectRevert("ticketID does not exist");
        ticketNFT.setUsed(2);
    }

    function testSetUsedUnauthorized() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");

        vm.prank(alice);
        vm.expectRevert("caller must be administrator of primary market");
        ticketNFT.setUsed(1);
    }

    function testSetExpired() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");

        vm.prank(address(this));
        ticketNFT.setUsed(1);
        vm.prank(address(this));
        vm.expectRevert("the ticket is used or expired");
        ticketNFT.setUsed(1);
    }

    function testSetUsedExpiredTime() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");

        vm.prank(address(this));
        vm.warp(block.timestamp + 10 days + 1 seconds);
        vm.expectRevert("the ticket is used or expired");
        ticketNFT.setUsed(1);
    }

    function testExpiryOf() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");
        assertEq(ticketNFT.expiryOf(1), block.timestamp + 10 days);
    }

    function testTotalSupply() public {
        _mintNFT(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderNameOf(1), "alice");

        _mintNFT(bob, "bob");
        assertEq(ticketNFT.balanceOf(bob), 1);
        assertEq(ticketNFT.holderOf(2), bob);
        assertEq(ticketNFT.holderNameOf(2), "bob");

        assertEq(ticketNFT.totalSupply(), 2);
    }
}