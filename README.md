# Coursework skeleton

This is the skeleton for the coursework of the Principle of Distributed Ledgers 2023.
It contains [the interfaces](./src/interfaces) of the contracts to implement and an [ERC20 implementation](./src/contracts/PurchaseToken.sol).

The repository uses [Foundry](https://book.getfoundry.sh/projects/working-on-an-existing-project).


# Directory Structure




``` bash
.
├── lib/
│   └── *
├── src/
│   ├── contracts/
│   │   ├── PrimaryMarket.sol
│   │   ├── PurchaseToken.sol
│   │   ├── SecondaryMarket.sol
│   │   └── TicketNFT.sol
│   └── interfaces/
│       ├── IERC20.sol
│       ├── IPrimaryMarket.sol
│       ├── ISecondaryMarket.sol
│       └── ITicketNFT.sol
├── test/
│   ├── PrimaryMarket.sol
│   ├── SecondaryMarket.sol
│   └── TicketNFT.sol
└── README.md

```
The contract implementations as shown above are inside the `src/contracts/` directory alongside it's corresponding tests inside the `test/` directory.

# Implementation

Each contract implemented inherits from its corresponding `I*.sol` interface. Due to the cyclic dependency inside PrimaryMarket and TicketNFT and additional `changeTicketNFT` function is added as a helper function in order to be able to change the address of the ticket being referenced upon instantiation. An example of how this is used can be seen in any of the test `setUp()` function. 

Some additional functions were also added either for completeness or for testing purposes such as the `changeNumTickets` function inside the PrimaryMarket contract. All of these functions however require for the sender to be the admin (owner) of the contract ensuring that the overall functionality is the same.

# Tests

Each test not only tests each individual function but also all the requirement satisfications specified in the specification and also the interface. Each of the tests for each contract has a `Base` contract used to instantiate variables and set up appropriate constants. This has the form of `Base*Test` which inherits from the `Test` contract inside the `forge-std` library.

A secondary contract which inherits from the `Base` contract is then defined solely for the purposes of testing. The contract is in the form `*Test` and all the functions listed in the contract will be in the form of `function test*()`.