// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "../interfaces/ITicketNFT.sol";
import "../interfaces/IPrimaryMarket.sol";
import "../../lib/forge-std/src/Test.sol";

contract TicketNFT is ITicketNFT {
    // Define the variables
    IPrimaryMarket private _IPrimaryMarket;

    uint public totalSupplyNum = 0;
    uint private currentTokenId = 1;

    mapping(address => uint256) private _balances; // Returns the number of tickets an address has
    mapping(uint256 => address) private _holders; // Returns the address of the holder of a ticket
    mapping(uint256 => string) private _holderNames; // Returns the name of the holder of a ticket
    mapping(uint256 => address) private _approved; // Returns the approved address for a ticket
    mapping(uint256 => bool) private _used_or_expired; // Returns whether a ticket has been used or expired
    mapping(uint256 => uint256) private _expiry; // Returns the expiry time of a ticket

    constructor(
        IPrimaryMarket PrimaryMarket
    ) {
        // Initialize the variables
        _IPrimaryMarket = PrimaryMarket;
    }

    // Define the functions

    function mint(address holder, string memory holderName) external {
        // Caller must be primary market
        require(msg.sender == address(_IPrimaryMarket), "caller must be primary market");

        // Mint a new ticket for `holder` with `holderName`
        _balances[holder] += 1;
        _holders[currentTokenId] = holder;
        _holderNames[currentTokenId] = holderName;
        _used_or_expired[currentTokenId] = false;
        _expiry[currentTokenId] = block.timestamp + 10 days;
        currentTokenId += 1;
        totalSupplyNum += 1;

        emit Transfer(address(0), holder, currentTokenId - 1);
    }

    function balanceOf(address holder) external view returns (uint256 balance) {
        // Return the number of tickets a `holder` has
        return _balances[holder];
    }

    function holderOf(uint256 ticketID) external view returns (address holder) {
        // Return the address of the holder of the `ticketID` ticket
        // ticketID must exist
        require(ticketID < currentTokenId && ticketID >= 1, "ticketID does not exist");
        return _holders[ticketID];
    }

    function transferFrom(
        address from,
        address to,
        uint256 ticketID
    ) external {
        // Transfer `ticketID` ticket from `from` to `to`
        // 'from' cannto be the zero address.
        require(from != address(0), "transfer cannot be from the zero address");
        // 'to' cannot be the zero address.
        require(to != address(0), "transfer cannot be to the zero address");
        // Caller must be the holder of the ticket or the approved address for it.
        require(msg.sender == _holders[ticketID] || msg.sender == _approved[ticketID], "caller must be the holder of the ticket or the approved address for it");
        // From must be the holder of the ticket.
        require(from == _holders[ticketID], "from must be the holder of the ticket");
        // Emits a 'Transfer' and an 'Approval' event.
        _balances[from] -= 1;
        _balances[to] += 1;
        _holders[ticketID] = to;
        _approved[ticketID] = address(0);
        emit Transfer(from, to, ticketID);
        emit Approval(to, address(0), ticketID);
    }

    function approve(address approved, uint256 ticketID) external {
        // Approve `approved` to manage the `ticketID` ticket
        // ticketID must exist
        require(ticketID < currentTokenId && ticketID >= 1, "ticketID does not exist");
        // Caller must be the holder of the ticket.
        require(msg.sender == _holders[ticketID], "caller must be the holder of the ticket");
        // Emits an 'Approval' event.
        _approved[ticketID] = approved;
        emit Approval(msg.sender, approved, ticketID);
    }

    function getApproved(uint256 ticketID) external view returns (address approved) {
        // Return the approved address for the `ticketID` ticket
        // TicketID must exist
        require(ticketID < currentTokenId && ticketID >= 1, "ticketID does not exist");
        return _approved[ticketID];
    }

    function holderNameOf(uint256 ticketID) external view returns (string memory holderName) {
        // Return the name of the holder of the `ticketID` ticket
        // ticketID must exist
        require(ticketID < currentTokenId && ticketID >= 1, "ticketID does not exist");
        return _holderNames[ticketID];
    }

    function updateHolderName(uint256 ticketID, string calldata newName) external {
        // Update the name of the holder of the `ticketID` ticket to `newName`
        // ticketID must exist
        require(ticketID < currentTokenId && ticketID >= 1, "ticketID does not exist");
        // Caller must be the holder of the ticket.
        require(msg.sender == _holders[ticketID], "caller must be the holder of the ticket");
        _holderNames[ticketID] = newName;
    }

    function setUsed(uint256 ticketID) external {
        // Mark the `ticketID` ticket as used
        // ticketID must exist
        require(ticketID < currentTokenId && ticketID >= 1, "ticketID does not exist");
        // the ticket must not be used or expired
        require(this.isExpiredOrUsed(ticketID) == false, "the ticket is used or expired");
        // Only the administrator of the primary market can call this function (NOT DONE)
        require(msg.sender == _IPrimaryMarket.admin(), "caller must be administrator of primary market");
        _used_or_expired[ticketID] = true;
    }

    function isExpiredOrUsed(uint256 ticketID) external view returns (bool) {
        // Return whether the `ticketID` ticket is used or expired
        // ticketID must exist
        require(ticketID < currentTokenId && ticketID >= 1, "ticketID does not exist");
        return _used_or_expired[ticketID] || block.timestamp > _expiry[ticketID];
    }


    /////////////// Additional Function Implementations
    function expiryOf(uint256 ticketID) external view returns (uint256) {
        // Return the expiry time of the `ticketID` ticket
        // ticketID must exist
        require(ticketID < currentTokenId && ticketID >= 1, "ticketID does not exist");
        return _expiry[ticketID];
    }

    function totalSupply() external view returns (uint256) {
        // Return the total number of tickets
        return totalSupplyNum;
    }
}
