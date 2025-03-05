# ERC721Airdrop Contract

## Overview
The `ERC721Airdrop` contract is an ERC-721 non-fungible token (NFT) contract that supports enumeration, burning, pausing, Merkle Proof-based airdrop, and signature-based airdrop claim mechanisms.

### Features:
1. **Enumerable**: Allows retrieving NFT IDs based on an index for both a specific user and globally.
2. **Burnable**: Tokens can be burned by the owner or an approved operator.
3. **Pausable**: The admin can pause or unpause all token transfers (minting, burning, and transfers) using `pause()` and `unpause()`.
4. **Merkle Proof Airdrop**:
   - Uses a Merkle tree to allow users to claim NFTs.
   - Leaf nodes are `keccak256` hashes of addresses.
   - The correct Merkle proof order must be used.
5. **Signature-based Airdrop**:
   - Users can claim an airdropped NFT using a signature signed by the admin.

---

## Contract Details

### State Variables
- `_name`: Token name (`ERC721AirDropToken`).
- `_symbol`: Token symbol (`EAT`).
- `_merkleRoot`: The Merkle root for verifying airdrop eligibility.
- `admin`: The contract administrator.
- `tokenCounter`: Keeps track of the minted token IDs.
- `dropAddresses`: A BitMap to track addresses that have claimed airdrops.

### Functions

#### **Admin Functions**
- `pause()`: Pauses all token operations.
- `unpause()`: Resumes token operations.
- `addAirdropWithMerkleRoot(bytes32 _merkleRoot_)`: Sets the Merkle root for the airdrop.
- `specificAirdropToken(address to)`: Allows the admin to directly airdrop an NFT to a specified address.

#### **Merkle Proof Airdrop**
- `claimWithMerkleProof(bytes32[] calldata merkleProofs)`: Allows eligible users to claim an NFT if they provide a valid Merkle proof.
- `_verify(bytes32[] calldata proof, bytes32 root, bytes32 leaf)`: Verifies if the given leaf and proof correspond to the Merkle root.
- `_processProof(bytes32[] calldata proof, bytes32 leaf)`: Processes the proof and computes the Merkle root.
- `commutativeKeccak256(bytes32 a, bytes32 b)`: Ensures the hash order is consistent.

#### **Signature-based Airdrop**
- `claimWithSignature(bytes memory signature)`: Allows users to claim an NFT if they provide a valid signature from the admin.
- `getMessageHash(address _address)`: Computes the hash of an address to be signed.
- `getETHMessageHash(bytes32 hash)`: Generates an Ethereum-specific message hash.
- `_recoverSigner(bytes32 messageHash, bytes memory signature)`: Recovers the signer’s address from a given signature.

#### **Burning**
- `burn(uint256 tokenId)`: Allows token holders to burn their NFT.

---

## Airdrop Process
### **Merkle Proof Airdrop Steps**
1. Generate a Merkle tree from an address list.
2. Set the Merkle root using `addAirdropWithMerkleRoot()`.
3. Users claim their NFT using `claimWithMerkleProof()` by providing a valid proof.

### **Signature-based Airdrop Steps**
1. The admin signs the message hash of the recipient's address.
2. The user calls `claimWithSignature()` with the provided signature.
3. The contract verifies the signature and mints an NFT if valid.

---

## Security Considerations
- Ensure the admin address is secured to prevent unauthorized airdrop claims.
- Only allow one claim per address by tracking claimed addresses in `dropAddresses`.
- Merkle proofs should be computed correctly to prevent claim failures.
- Signature verification should use the correct Ethereum-specific hash to prevent signature replay attacks.

---

## Deployment & Usage
1. Deploy the contract using a Solidity-compatible environment.
2. Use the `addAirdropWithMerkleRoot()` function to set the Merkle root.
3. Call `pause()` or `unpause()` as needed to control token operations.
4. Users can claim their NFTs via `claimWithMerkleProof()` or `claimWithSignature()`.

---

## License
This contract is licensed under the MIT License.

