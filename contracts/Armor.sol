// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

////////////////////////////////////////////////////////////////
// OPENZEPPELIN V5 IMPORTS
////////////////////////////////////////////////////////////////
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title ArmorNFT
 * @author Mohammad Hossein Ghiasvand
 * @notice Enterprise-grade Root NFT contract for the Dragon Armor ecosystem.
 * @dev Fully optimized for Gas, compliant with OpenZeppelin v5.x, and structured for hierarchical verification.
 */
contract ArmorNFT is ERC721, ERC721Burnable, ERC721Pausable, ERC2981, Ownable {
    using Strings for uint256;

    ////////////////////////////////////////////////////////////////
    // CONSTANTS & STORAGE
    ////////////////////////////////////////////////////////////////

    /// @notice Hardcoded supply cap for the collection to secure rarity.
    uint256 public constant MAX_SUPPLY = 100;

    /// @dev Tracking the next token ID to be minted (starts at 0).
    uint256 private _nextTokenId;

    /// @dev Internal storage for the IPFS folder directory.
    string private _baseMetadataURI;

    ////////////////////////////////////////////////////////////////
    // CUSTOM ERRORS (Gas Saving over Require)
    ////////////////////////////////////////////////////////////////
    error InvalidBaseURI();
    error MaxSupplyReached();
    error TokenDoesNotExist();

    ////////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////////
    event ArmorMinted(address indexed to, uint256 indexed tokenId);
    event BaseURIUpdated(string newBaseURI);

    ////////////////////////////////////////////////////////////////
    // CONSTRUCTOR
    ////////////////////////////////////////////////////////////////

    /**
     * @param baseURI_ The IPFS folder base path ending with a trailing slash (e.g., ipfs://Qm.../)
     * @param royaltyReceiver_ The wallet address to receive secondary market royalties.
     * @param royaltyFeeNumerator_ Fee in basis points (e.g., 500 for 5%).
     */
    constructor(
        string memory baseURI_,
        address royaltyReceiver_,
        uint96 royaltyFeeNumerator_
    ) 
        ERC721("Dragon Armor", "DARMOR") 
        Ownable(msg.sender) 
    {
        if (bytes(baseURI_).length == 0) revert InvalidBaseURI();
        
        _baseMetadataURI = baseURI_;
        _setDefaultRoyalty(royaltyReceiver_, royaltyFeeNumerator_);
    }

    ////////////////////////////////////////////////////////////////
    // MINT & BURN LOGIC
    ////////////////////////////////////////////////////////////////

    /**
     * @notice Mints a new Dragon Armor NFT to the specified address.
     * @param to The wallet address receiving the NFT.
     * @return tokenId The newly generated token identifier.
     */
    function mint(address to) external onlyOwner returns (uint256) {
        uint256 currentTokenId = _nextTokenId;
        if (currentTokenId >= MAX_SUPPLY) revert MaxSupplyReached();

        // Safe unchecked increment for gas optimization
        unchecked {
            _nextTokenId = currentTokenId + 1;
        }

        _safeMint(to, currentTokenId);

        emit ArmorMinted(to, currentTokenId);
        
        return currentTokenId;
    }

    /**
     * @notice Burns a specific token, destroying it permanently.
     * @dev Overrides ERC721Burnable to ensure total compliance.
     */
    function burn(uint256 tokenId) public override {
        super.burn(tokenId);
    }

    ////////////////////////////////////////////////////////////////
    // METADATA & URI MANAGEMENT
    ////////////////////////////////////////////////////////////////

    /**
     * @notice Constructs the full URI pointing to the IPFS JSON file (e.g., ipfs://CID/0.json).
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); 

        return string(abi.encodePacked(_baseMetadataURI, tokenId.toString(), ".json"));
    }

    /**
     * @notice Updates the base IPFS folder link if necessary.
     */
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        if (bytes(newBaseURI).length == 0) revert InvalidBaseURI();
        _baseMetadataURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    function baseURI() external view returns (string memory) {
        return _baseMetadataURI;
    }

    ////////////////////////////////////////////////////////////////
    // ROYALTY CONFIGURATION (EIP-2981)
    ////////////////////////////////////////////////////////////////

    /**
     * @notice Updates the global royalty configuration for Marketplaces (OpenSea, Rarible, etc).
     */
    function setRoyaltyInfo(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    ////////////////////////////////////////////////////////////////
    // EMERGENCY CONTROLS (Pausable)
    ////////////////////////////////////////////////////////////////

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    ////////////////////////////////////////////////////////////////
    // REQUIRED OVERRIDES (OpenZeppelin 5.x Compliance)
    ////////////////////////////////////////////////////////////////

    function _update(
        address to, 
        uint256 tokenId, 
        address auth
    ) internal override(ERC721, ERC721Pausable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}