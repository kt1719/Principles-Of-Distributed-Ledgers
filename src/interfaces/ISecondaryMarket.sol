// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

/**
 * @dev Required interface for the secondary market.
 * The secondary market is the point of sale for tickets after they have been initially purchased from the primary market
 */
interface ISecondaryMarket {
    /**
     * @dev Event emitted when a new ticket listing is created
     */
    event Listing(
        uint256 indexed ticketID,
        address indexed holder,
        uint256 price
    );

    /**
     * @dev Event emitted when an amount of the purchase token is transferred from
     */
    event Purchase(
        address indexed purchaser,
        uint256 indexed ticketID,
        uint256 price,
        string newName
    );
    /**
     * @dev Event emitted when a ticket is delisted
     */
    event Delisting(uint256 indexed ticketID);

    /**
     * @dev This method lists a ticket with `ticketID` for sale by transferring the ticket
     * such that it is held by this contract. Only the current owner of a specific
     * ticket is able to list that ticket on the secondary market. The purchase
     * `price` is specified in an amount of `PurchaseToken`.
     * Note: Only non-expired and unused tickets can be listed
     */
    function listTicket(uint256 ticketID, uint256 price) external;

    /** @dev This method allows the msg.sender to purchase a listed ticket with `ticketID`
     * by paying the purchase price that was specified when the ticket was listed.
     * `name` gives the new name that should be stated on the ticket when it is purchased.
     * Note: Only non-expired and unused tickets can be purchased and there is a
     * fee charged every time a purchase is made. The fee is charged on the price.
     * The final amount that the lister of the ticket receives is the price
     * minus the fee. The fee should go to the admin of the primary market.
     */
    function purchase(uint256 ticketID, string calldata name) external;

    /** @dev This method delists a previously listed ticket with `ticketID`. Only the account that
     * listed the ticket may delist the ticket. The ticket should be transferred back
     * to msg.sender, i.e., the lister.
     */
    function delistTicket(uint256 ticketID) external;

    // Additional functions
    function ticketListed(uint256 ticketID) external view returns (bool);

    function getTicketPrice(uint256 ticketID) external view returns (uint256);

    function getTicketSeller(uint256 ticketID) external view returns (address);
}
