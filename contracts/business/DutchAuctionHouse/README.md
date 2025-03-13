# Dutch Auction House

## Overview
The **DutchAuctionHouse** is a smart contract that facilitates Dutch-style auctions for ERC721 NFTs. Sellers can list their NFTs with an initial price that gradually decreases over time until a buyer makes a bid. The contract ensures fair and secure auction transactions and manages seller earnings and fees.

## Features
- **NFT White-listing**: Only approved ERC721 NFTs can be auctioned.
- **Dutch Auction Mechanism**:
  - Sellers set an initial (high) price and a final (low) price.
  - The price decreases at regular intervals until a buyer places a bid.
- **Auction Management**:
  - Sellers can list NFTs for auction.
  - Bidders can purchase NFTs by sending ETH matching the current auction price.
  - Sellers can withdraw earned ETH.
- **Admin Controls**:
  - Add/remove NFTs from the whitelist.
  - Set platform fees.
  - Withdraw platform profits.

## Smart Contract Breakdown
### DutchAuctionHouse
- **Structs**:
  - `AuctionItem`: Stores auction-related details (NFT, pricing, time, and buyer info).
- **Events**:
  - `ERC721Received`: Triggered when the contract receives an NFT.
  - `BidSuccess`: Triggered when a bid is successfully placed.
  - `NFTSupportAdded`/`NFTSupportRemoved`: Emitted when an NFT collection is added/removed from the whitelist.
- **Errors**:
  - Multiple custom errors to handle invalid operations (e.g., `UnsupportedToken`, `AuctionItemNotFound`, etc.).
- **Functions**:
  - `addNFTSupport(address)`, `removeNFTSupport(address)`: Admin functions to manage the NFT whitelist.
  - `createAuction(...)`: List an NFT for auction.
  - `bidAuction(uint256)`: Participate in an auction.
  - `getAuctionPrice(uint256)`: Compute the current auction price.
  - `withdraw()`: Withdraw seller earnings.
  - `getBackNft(address, uint256, address)`: Retrieve an NFT if the auction expires.
  - `setFeeRate(uint256)`, `send()`: Admin functions to manage fees and withdraw platform profits.

## Usage
- Sellers must first transfer their NFT to the contract using `safeTransferFrom`.
- Once received, sellers can list the NFT for auction using `createAuction()`.
- Buyers can check the current price using `getAuctionPrice()` and bid using `bidAuction()`.
- Sellers can withdraw earnings via `withdraw()`.
- The admin can set fees using `setFeeRate()` and withdraw platform profits using `send()`.

## Security Considerations
- The contract uses `onlyAdmin` for sensitive operations.
- Ensures NFTs are only accepted from whitelisted collections.
- Uses Solidity's `require()` and custom errors to prevent invalid transactions.

## License
This project is licensed under the MIT License.

