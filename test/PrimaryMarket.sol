// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../lib/forge-std/src/Test.sol";
import "../src/contracts/TicketNFT.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/contracts/PrimaryMarket.sol";

contract BasePrimaryMarketTest is Test {
    // Define events
    event Purchase(address indexed holder, string indexed holderName);

    // Define the variables
    TicketNFT ticketNFT;
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
}

// Define test contract
contract PrimaryMarketTest is BasePrimaryMarketTest {
    function testAdmin() public {
        assertEq(primaryMarket.admin(), address(this));
    }

    function testPurchase() public {
        // Check admin balance before purchase
        assertEq(purchaseToken.balanceOf(address(this)), 0);

        vm.deal(alice, nftPrice/100);
        vm.prank(alice);
        purchaseToken.mint{value: nftPrice/100}();
        assertEq(purchaseToken.balanceOf(alice), nftPrice);
        vm.prank(alice);
        purchaseToken.approve(address(primaryMarket), nftPrice);
        vm.prank(alice);
        vm.expectEmit(true, true, false, false);
        emit Purchase(alice, "alice");
        primaryMarket.purchase("alice");

        // Check balance after purchase
        assertEq(purchaseToken.balanceOf(address(this)), nftPrice);
        assertEq(purchaseToken.balanceOf(alice), 0);
    }

    function testPurchaseNotEnoughFunds() public {
        vm.prank(alice);
        vm.expectRevert("insufficient balance");
        primaryMarket.purchase("alice");
    }

    function testPurchaseTooManyTickets() public {
        vm.prank(address(this));
        primaryMarket.changeNumTickets(1000);

        vm.deal(alice, nftPrice/100);
        vm.prank(alice);
        purchaseToken.mint{value: nftPrice/100}();
        assertEq(purchaseToken.balanceOf(alice), nftPrice);
        vm.prank(alice);
        purchaseToken.approve(address(primaryMarket), nftPrice);
        vm.prank(alice);
        vm.expectRevert("number of tickets exceeded");
        primaryMarket.purchase("alice");
    }
}