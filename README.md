# 🐉 Dragon Armor Ecosystem

Dragon Armor
      │
      ▼
Dragon Helmet
      │
      ▼
Dragon Sword
      │
      ▼
Moonlight Sword
      │
      ▼
Dragon Shield

A production-oriented Hierarchical NFT Ecosystem developed with Solidity and OpenZeppelin Contracts v5.

Unlike a traditional ERC-721 collection, this project models a parent-child NFT architecture where every asset can be cryptographically linked to another NFT, enabling hierarchical ownership relationships and modular digital asset structures.

---

# Architecture

```
Dragon Armor
    └── Dragon Helmet
            └── Dragon Sword
                    └── Moonlight Sword
                            └── Dragon Shield
```

Each NFT is deployed as an independent ERC-721 smart contract while preserving references to its parent NFT, creating a verifiable hierarchical asset ecosystem.

---

# Project Goals

This project demonstrates how ERC-721 NFTs can be extended beyond simple collectibles into structured digital assets with logical relationships.

The architecture is designed to serve as a foundation for:

- Hierarchical Digital Assets
- Modular Game Equipment Systems
- RPG Inventory Structures
- Digital Identity Trees
- Real Estate Asset Hierarchies
- Enterprise NFT Architectures

---

# Key Features

## Hierarchical NFT Architecture

Every child NFT stores a verifiable reference to its parent NFT.

Hierarchy:

- Dragon Helmet → Dragon Armor
- Dragon Sword → Dragon Helmet
- Moonlight Sword → Dragon Sword
- Dragon Shield → Moonlight Sword

This allows decentralized applications to reconstruct the complete asset hierarchy directly from on-chain data.

---

## Independent Smart Contracts

Each asset category is implemented as an independent ERC-721 smart contract.

- ArmorNFT
- HelmetNFT
- SwordNFT
- MoonlightSwordNFT
- ShieldNFT

This modular architecture improves scalability, maintainability, and future extensibility.

---

## Parent–Child Relationship Verification

Every NFT maintains an immutable reference to its parent NFT by storing:

- Parent Contract Address
- Parent Token ID

This enables secure verification of ownership relationships across multiple smart contracts.

---

## ERC-2981 Royalties

Supports ERC-2981 royalty standard for secondary marketplace sales.

---

## IPFS Metadata

Metadata and artwork are stored on IPFS using Pinata.

The contracts implement configurable BaseURI management, allowing metadata updates without redeploying smart contracts.

---

## Administrative Controls

- Ownable Access Control
- Pausable Contracts
- Burnable NFTs
- Configurable BaseURI
- Royalty Management

---

## Gas Optimization

The contracts include multiple gas optimization techniques:

- Custom Errors
- Efficient Storage Layout
- OpenZeppelin Contracts v5
- Solidity 0.8.x Best Practices

---

# Technology Stack

- Solidity ^0.8.24
- OpenZeppelin Contracts v5
- ERC721
- ERC2981
- IPFS
- Pinata
- MetaMask
- Remix IDE
- Sepolia Testnet

---

# Smart Contract Overview

| Contract | Role |
|----------|------|
| ArmorNFT | Root NFT |
| HelmetNFT | Child of Armor |
| SwordNFT | Child of Helmet |
| MoonlightSwordNFT | Child of Sword |
| ShieldNFT | Child of Moonlight Sword |

---

# Future Roadmap

- NFT Marketplace
- NFT Renting
- Bundle Listings
- Auctions
- Offer System
- Cross-Collection Verification
- Frontend dApp (React + Ethers.js)

---

# License

MIT License
