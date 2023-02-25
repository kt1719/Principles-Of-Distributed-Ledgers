// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "../interfaces/IERC20.sol";
import "../interfaces/ITicketNFT.sol";
import "../interfaces/ISecondaryMarket.sol";
import "../interfaces/IPrimaryMarket.sol";
// import test from forge
import "../../lib/forge-std/src/Test.sol";

contract SecondaryMarket is ISecondaryMarket {
    // Define the variables
    ITicketNFT private _ticketNFT;
    IPrimaryMarket private _primaryMarket;
    IERC20 private _paymentToken;

    mapping(uint256 => uint256) private _ticketPrice; // Returns the price of a ticket
    mapping(uint256 => address) private _ticketSeller; // Returns the address of the seller of a ticket
    mapping(uint256 => bool) private _ticketListed; // Returns true if the ticket is listed for sale

    constructor(
        IERC20 paymentToken,
        ITicketNFT ticketNFT,
        IPrimaryMarket primaryMarket
    ) {
        // Initialize the variables
        _ticketNFT = ticketNFT;
        _paymentToken = paymentToken;
        _primaryMarket = primaryMarket;
    }

    function listTicket(uint256 ticketID, uint256 price) external {
        // Checks that the ticket is not already listed
        require(!_ticketListed[ticketID], "ticket already listed");
        // Checks that the ticket is owned by the seller
        require(_ticketNFT.holderOf(ticketID) == msg.sender, "not the owner of the ticket");
        // Checks that the price is greater than 0
        require(price > 0, "price must be greater than 0");
        // Checks that the ticket is not expired and unused
        require(!_ticketNFT.isExpiredOrUsed(ticketID), "ticket is expired or used");
        // Check that the secondary market is approved to transfer the ticket
        require(_ticketNFT.getApproved(ticketID) == address(this), "secondary market not approved for listing");
        // Lists the ticket for sale
        _ticketPrice[ticketID] = price;
        _ticketSeller[ticketID] = msg.sender;
        _ticketListed[ticketID] = true;
        emit Listing(ticketID, _ticketNFT.holderOf(ticketID), price);
        // Transfer ownership to the secondary marketplace
        _ticketNFT.transferFrom(msg.sender, address(this), ticketID);
    }

    function purchase(uint256 ticketID, string calldata name) external {
        // Checks that the ticket is listed
        require(_ticketListed[ticketID], "ticket not listed");
        // Checks that the buyer has enough balance
        require(_paymentToken.balanceOf(msg.sender) >= _ticketPrice[ticketID], "insufficient balance");
        // Checks that the ticket is not expired and unused
        require(!_ticketNFT.isExpiredOrUsed(ticketID), "ticket is expired or used");
        // 5% fee charged to the seller given to admin
        uint256 fee = _ticketPrice[ticketID] * 5 / 100;
        // Changes the name of the ticket owner
        _ticketNFT.updateHolderName(ticketID, name);
        // Transfers the fee to the admin
        _paymentToken.transferFrom(msg.sender, _primaryMarket.admin(), fee);
        // Transfers the payment to the seller
        _paymentToken.transferFrom(msg.sender, _ticketSeller[ticketID], _ticketPrice[ticketID]-fee);
        // Delists the ticket
        this.delistTicket(ticketID);
        // Transfers the ticket to the buyer
        _ticketNFT.transferFrom(address(this), msg.sender, ticketID);
        // _ticketNFT.updateHolderName(ticketID, name);
        emit Purchase(msg.sender, ticketID, _ticketPrice[ticketID], name);
    }

    function delistTicket(uint256 ticketID) external {
        // Checks that the ticket is owned by the seller or holderOf or by _ticketSeller
        require(_ticketNFT.holderOf(ticketID) == msg.sender || _ticketSeller[ticketID] == msg.sender, "not the owner of the ticket");
        // Checks that the ticket is listed
        require(_ticketListed[ticketID], "ticket not listed");
        // Delists the ticket
        _ticketListed[ticketID] = false;
        // Transfers the ticket back to the seller
        _ticketNFT.transferFrom(address(this), msg.sender, ticketID);
        emit Delisting(ticketID);
    }

    // Additional function implementation
    function ticketListed(uint256 ticketID) external view returns (bool) {
        return _ticketListed[ticketID];
    }

    function getTicketPrice(uint256 ticketID) external view returns (uint256) {
        // Ensure that the ticket is listed
        require(_ticketListed[ticketID], "ticket not listed");
        return _ticketPrice[ticketID];
    }

    function getTicketSeller(uint256 ticketID) external view returns (address) {
        // Ensure that the ticket is listed
        require(_ticketListed[ticketID], "ticket not listed");
        return _ticketSeller[ticketID];
    }
}