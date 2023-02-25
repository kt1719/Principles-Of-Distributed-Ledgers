// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "../interfaces/IERC20.sol";
import "../interfaces/ITicketNFT.sol";
import "../interfaces/IPrimaryMarket.sol";

contract PrimaryMarket is IPrimaryMarket {

    // Define the variables
    ITicketNFT private _ticketNFT;
    IERC20 private _paymentToken;
    // Token price fixed at 100e18 units
    uint256 private _initialTokenPrice = 100e18;
    address private _admin;
    uint256 private _numTickets = 0;


    constructor(
        IERC20 paymentToken,
        ITicketNFT ticketNFT
    ) {
        // Initialize the variables
        _ticketNFT = ticketNFT;
        _paymentToken = paymentToken;
        _admin = msg.sender;
    }

    function admin() external view returns (address){
        // Returns the address of the admin
        // This should be the address that created the contract
        return _admin;
    }

    function purchase(string memory holderName) external {
        // Takes the initial NFT token holder's name as a string input
        // Number of tickets should be limited to 1000
        require(_numTickets < 1000, "number of tickets exceeded");
        // and transfers ERC20 tokens from the purchaser to the admin of this contract
        require(_paymentToken.balanceOf(msg.sender) >= _initialTokenPrice, "insufficient balance");
        _paymentToken.transferFrom(msg.sender, _admin, _initialTokenPrice);
        _ticketNFT.mint(msg.sender, holderName);
        _numTickets += 1;
        emit Purchase(msg.sender, holderName);
    }

    function changeTicketNFT(ITicketNFT NFT) external { // Function used since there is a cyclic dependency in instantiation
        // Only the admin can change the payment token
        require(msg.sender == _admin, "only admin can change payment token");
        _ticketNFT = NFT;
    }

    // Additional helper functions
    function changeNumTickets(uint256 numTickets) external {
        // Only the admin can change the number of tickets
        require(msg.sender == _admin, "only admin can change number of tickets");
        _numTickets = numTickets;
    }
}