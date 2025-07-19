# Clarity Auction Platform

A decentralized auction platform built on Stacks blockchain using Clarity smart contracts.

## System Overview

The auction platform consists of five interconnected smart contracts that handle the complete auction lifecycle:

### Core Contracts

1. **Item Listing Contract** (`item-listing.clar`)
    - Records auction item details and metadata
    - Sets starting bids and auction parameters
    - Manages item ownership and transfer rights

2. **Bid Placement Contract** (`bid-placement.clar`)
    - Handles competitive bidding process
    - Validates bid amounts and timing
    - Maintains bid history and current highest bid

3. **Winner Determination Contract** (`winner-determination.clar`)
    - Identifies highest bidder when auction closes
    - Manages auction state transitions
    - Handles tie-breaking scenarios

4. **Payment Escrow Contract** (`payment-escrow.clar`)
    - Secures funds from winning bidder
    - Manages payment release upon delivery
    - Handles refunds for unsuccessful bids

5. **Dispute Resolution Contract** (`dispute-resolution.clar`)
    - Manages conflicts between buyers and sellers
    - Provides arbitration mechanisms
    - Handles dispute outcomes and resolutions

## Key Features

- **Decentralized Bidding**: No central authority controls the auction process
- **Secure Escrow**: Funds are held securely until item delivery
- **Transparent Process**: All bids and transactions are publicly verifiable
- **Dispute Handling**: Built-in mechanisms for resolving conflicts
- **Time-based Auctions**: Automatic closure based on block height

## Data Structures

### Auction Item
- Item ID (unique identifier)
- Seller principal
- Item description and metadata
- Starting bid amount
- Auction duration (in blocks)
- Current status

### Bid Record
- Bidder principal
- Bid amount
- Timestamp (block height)
- Auction ID reference

### Escrow Record
- Auction ID
- Locked amount
- Release conditions
- Dispute status

## Usage Flow

1. **List Item**: Seller creates auction with item details and starting bid
2. **Place Bids**: Buyers submit competitive bids during auction period
3. **Determine Winner**: System identifies highest bidder at auction close
4. **Escrow Payment**: Winner's payment is held in escrow
5. **Complete Transaction**: Payment released upon successful delivery
6. **Handle Disputes**: Resolution process for any conflicts

## Security Features

- Input validation on all contract functions
- Access control for sensitive operations
- Overflow protection for arithmetic operations
- State consistency checks
- Emergency pause mechanisms

## Testing

Comprehensive test suite covers:
- Contract deployment and initialization
- Auction creation and bidding scenarios
- Winner determination edge cases
- Escrow and payment flows
- Dispute resolution processes

## Deployment

1. Deploy contracts in dependency order
2. Initialize contract parameters
3. Set up inter-contract permissions
4. Verify deployment on testnet before mainnet

## Error Codes

- ERR-NOT-AUTHORIZED (u100): Caller lacks required permissions
- ERR-INVALID-INPUT (u101): Invalid function parameters
- ERR-AUCTION-NOT-FOUND (u102): Referenced auction does not exist
- ERR-AUCTION-ENDED (u103): Auction has already closed
- ERR-INSUFFICIENT-FUNDS (u104): Bid amount too low
- ERR-ALREADY-RESOLVED (u105): Dispute already handled
