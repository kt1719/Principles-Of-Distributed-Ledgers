// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

/**
 * @dev Required interface for the primary market.
 * The primary market is the first point of sale for tickets.
 * It is responsible for minting tickets and transferring them to the purchaser.
 * In this implementation, the purchase price is fixed at 100e18 purchase tokens
 * and the maximum number of tickets that can be purchased is 1000.
 * The purchase token is an ERC20 token that is specified when the contract is deployed.
 * The NFT to be minted is an implementation of the ITicketNFT interface and should be created (i.e. deployed)
 * when the contract implementing this interface is deployed.
 */
interface IPrimaryMarket {
    /**
     * @dev Emitted when a purchase by `holder` occurs, with `holderName` specified.
     */
    event Purchase(address indexed holder, string indexed holderName);

    /**
     * @dev Returns the administrator of the primary market.
     * This should be the address that created the contract.
     */
    function admin() external view returns (address);

    /**
     * @dev Takes the initial NFT token holder's name as a string input
     * and transfers ERC20 tokens from the purchaser to the admin of this contract
     */
    function purchase(string memory holderName) external;

    // Additional helper functions
    function changeNumTickets(uint256 numTickets) external;
}
