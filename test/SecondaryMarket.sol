// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../lib/forge-std/src/Test.sol";
import "../src/contracts/TicketNFT.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/contracts/PrimaryMarket.sol";
import "../src/contracts/SecondaryMarket.sol";

contract BaseSecondaryMarketTest is Test {
    // Define events
    event Listing(
        uint256 indexed ticketID,
        address indexed holder,
        uint256 price
    );

    event Purchase(
        address indexed purchaser,
        uint256 indexed ticketID,
        uint256 price,
        string newName
    );

    event Delisting(uint256 indexed ticketID);

    // Define the variables
    TicketNFT ticketNFT;
    PrimaryMarket primaryMarket;
    SecondaryMarket secondaryMarket;
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
        secondaryMarket = new SecondaryMarket(purchaseToken, ticketNFT, primaryMarket);
    }
}

// Define test contract
contract SecondaryMarketTest is BaseSecondaryMarketTest {
    function testListTicket() public {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        vm.prank(alice);
        ticketNFT.approve(address(secondaryMarket), 1);

        vm.prank(alice);
        vm.expectEmit(true, true, true, false);
        emit Listing(1, alice, nftPrice + 100);
        secondaryMarket.listTicket(1, nftPrice + 100);
        assertEq(secondaryMarket.ticketListed(1), true);
        assertEq(secondaryMarket.getTicketPrice(1), nftPrice + 100);
        assertEq(secondaryMarket.getTicketSeller(1), alice);
        assertEq(ticketNFT.holderOf(1), address(secondaryMarket));
    }

    function testListTicketUnauthorized() public {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        vm.prank(alice);
        ticketNFT.approve(address(secondaryMarket), 1);

        vm.prank(bob);
        vm.expectRevert("not the owner of the ticket");
        secondaryMarket.listTicket(1, nftPrice + 100);
    }

    function testListTicketAlreadyListed() public {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        vm.prank(alice);
        ticketNFT.approve(address(secondaryMarket), 1);

        vm.prank(alice);
        secondaryMarket.listTicket(1, nftPrice + 100);
        vm.expectRevert("ticket already listed");
        vm.prank(alice);
        secondaryMarket.listTicket(1, nftPrice + 100);
    }

    function testListTicketUsed() public {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        vm.prank(alice);
        ticketNFT.approve(address(secondaryMarket), 1);

        vm.prank(address(this));
        ticketNFT.setUsed(1);
        vm.prank(alice);
        vm.expectRevert("ticket is expired or used");
        secondaryMarket.listTicket(1, nftPrice + 100);
    }

    function testListTicketExpired() public {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        vm.prank(alice);
        ticketNFT.approve(address(secondaryMarket), 1);

        vm.warp(block.timestamp + 10 days + 1 seconds);
        vm.prank(alice);
        vm.expectRevert("ticket is expired or used");
        secondaryMarket.listTicket(1, nftPrice + 100);
    }

    function testListTicketNotApproved() public {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");

        vm.prank(alice);
        vm.expectRevert("secondary market not approved for listing");
        secondaryMarket.listTicket(1, nftPrice + 100);
    }

    function testPurchase() public {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        vm.prank(alice);
        ticketNFT.approve(address(secondaryMarket), 1);

        vm.prank(alice);
        secondaryMarket.listTicket(1, nftPrice + 100);

        vm.deal(bob, (nftPrice + 100)/100);
        vm.prank(bob);
        purchaseToken.mint{value: (nftPrice + 100)/100}();
        assertEq(purchaseToken.balanceOf(bob), (nftPrice + 100));
        vm.prank(bob);
        purchaseToken.approve(address(secondaryMarket), (nftPrice + 100));
        vm.prank(bob);
        vm.expectEmit(true, false, false, false);
        emit Delisting(1);
        vm.expectEmit(true, true, true, true);
        emit Purchase(bob, 1, nftPrice + 100, "bob");
        secondaryMarket.purchase(1, "bob");

        assertEq(secondaryMarket.ticketListed(1), false);
        assertEq(ticketNFT.holderOf(1), bob);
        assertEq(ticketNFT.holderNameOf(1), "bob");
        assertEq(purchaseToken.balanceOf(bob), 0);
        uint256 fee = (nftPrice + 100) * 5 / 100;
        assertEq(purchaseToken.balanceOf(alice), nftPrice + 100 - fee);
        assertEq(purchaseToken.balanceOf(address(this)), fee);
    }

    function testPurchaseInsufficientBalance() public {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        vm.prank(alice);
        ticketNFT.approve(address(secondaryMarket), 1);

        vm.prank(alice);
        secondaryMarket.listTicket(1, nftPrice + 100);

        vm.prank(charlie);
        purchaseToken.approve(address(secondaryMarket), (nftPrice + 100));
        vm.prank(charlie);
        vm.expectRevert("insufficient balance");
        secondaryMarket.purchase(1, "bob");
    }

    function testPurchaseTicketNotListed() public {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        vm.prank(alice);
        ticketNFT.approve(address(secondaryMarket), 1);

        vm.deal(charlie, (nftPrice + 100)/100);
        vm.prank(charlie);
        purchaseToken.mint{value: (nftPrice + 100)/100}();
        assertEq(purchaseToken.balanceOf(charlie), (nftPrice + 100));
        vm.prank(charlie);
        purchaseToken.approve(address(secondaryMarket), (nftPrice + 100));
        vm.prank(charlie);
        vm.expectRevert("ticket not listed");
        secondaryMarket.purchase(1, "bob");
    }

    function testPurchaseTicketExpired() public {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        vm.prank(alice);
        ticketNFT.approve(address(secondaryMarket), 1);

        vm.prank(alice);
        secondaryMarket.listTicket(1, nftPrice + 100);

        vm.deal(charlie, (nftPrice + 100)/100);
        vm.prank(charlie);
        purchaseToken.mint{value: (nftPrice + 100)/100}();
        assertEq(purchaseToken.balanceOf(charlie), (nftPrice + 100));
        
        vm.warp(block.timestamp + 10 days + 1 seconds);
        
        vm.prank(charlie);
        purchaseToken.approve(address(secondaryMarket), (nftPrice + 100));
        vm.prank(charlie);
        vm.expectRevert("ticket is expired or used");
        secondaryMarket.purchase(1, "bob");
    }

    function testPurchaseTicketUsed() public {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        vm.prank(alice);
        ticketNFT.approve(address(secondaryMarket), 1);

        vm.prank(alice);
        secondaryMarket.listTicket(1, nftPrice + 100);
        vm.prank(address(this));
        ticketNFT.setUsed(1);

        vm.deal(charlie, (nftPrice + 100)/100);
        vm.prank(charlie);
        purchaseToken.mint{value: (nftPrice + 100)/100}();
        assertEq(purchaseToken.balanceOf(charlie), (nftPrice + 100));
        vm.prank(charlie);
        purchaseToken.approve(address(secondaryMarket), (nftPrice + 100));
        vm.prank(charlie);
        vm.expectRevert("ticket is expired or used");
        secondaryMarket.purchase(1, "charlie");
    }

    function testPurchaseSecondaryMarketNotApproved() public {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        vm.prank(alice);
        ticketNFT.approve(address(secondaryMarket), 1);

        vm.prank(alice);
        secondaryMarket.listTicket(1, nftPrice + 100);

        vm.deal(bob, (nftPrice + 100)/100);
        vm.prank(bob);
        purchaseToken.mint{value: (nftPrice + 100)/100}();
        assertEq(purchaseToken.balanceOf(bob), (nftPrice + 100));
        vm.prank(bob);
        vm.expectRevert("ERC20: insufficient allowance");
        secondaryMarket.purchase(1, "bob");
    }

    function testDelistTicket() public {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        vm.prank(alice);
        ticketNFT.approve(address(secondaryMarket), 1);

        vm.prank(alice);
        secondaryMarket.listTicket(1, nftPrice + 100);

        vm.prank(alice);
        vm.expectEmit(true, false, false, false);
        emit Delisting(1);
        secondaryMarket.delistTicket(1);

        assertEq(secondaryMarket.ticketListed(1), false);
    }

    function testDelistTicketNotListed() public {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        vm.prank(alice);
        ticketNFT.approve(address(secondaryMarket), 1);

        vm.prank(alice);
        vm.expectRevert("ticket not listed");
        secondaryMarket.delistTicket(1);
    }

    function testDelistTicketNotOwner() public {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        vm.prank(alice);
        ticketNFT.approve(address(secondaryMarket), 1);

        vm.prank(alice);
        secondaryMarket.listTicket(1, nftPrice + 100);

        vm.prank(bob);
        vm.expectRevert("not the owner of the ticket");
        secondaryMarket.delistTicket(1);
    }

    function testGetTicketListed() public {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        vm.prank(alice);
        ticketNFT.approve(address(secondaryMarket), 1);

        vm.prank(alice);
        secondaryMarket.listTicket(1, nftPrice + 100);

        assertEq(secondaryMarket.ticketListed(1), true);
    }

    function testGetTicketListedNotListed() public {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        vm.prank(alice);
        ticketNFT.approve(address(secondaryMarket), 1);

        assertEq(secondaryMarket.ticketListed(1), false);
    }

    function testGetTicketPrice() public {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        vm.prank(alice);
        ticketNFT.approve(address(secondaryMarket), 1);

        vm.prank(alice);
        secondaryMarket.listTicket(1, nftPrice + 100);

        assertEq(secondaryMarket.getTicketPrice(1), nftPrice + 100);
    }

    function testGetTicketSeller() public {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        vm.prank(alice);
        ticketNFT.approve(address(secondaryMarket), 1);

        vm.prank(alice);
        secondaryMarket.listTicket(1, nftPrice + 100);

        assertEq(secondaryMarket.getTicketSeller(1), alice);
    }
}