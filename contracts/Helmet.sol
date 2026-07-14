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

////////////////////////////////////////////////////////////////
// INTERFACES
////////////////////////////////////////////////////////////////
interface IParentArmor {
    function ownerOf(uint256 tokenId) external view returns (address);
}

/**
 * @title HelmetNFT
 * @author Mohammad Hossein Ghiasvand
 * @notice Enterprise-grade Child NFT contract linked structurally to ArmorNFT.
 * @dev Enforces cross-contract validation during minting to verify lineage constraints.
 */
contract HelmetNFT is ERC721, ERC721Burnable, ERC721Pausable, ERC2981, Ownable {
    using Strings for uint256;

    ////////////////////////////////////////////////////////////////
    // CONSTANTS & STORAGE
    ////////////////////////////////////////////////////////////////

    uint256 public constant MAX_SUPPLY = 100;
    
    /// @notice The immutable contract address of the parent ArmorNFT.
    address public immutable parentArmorContract;

    uint256 private _nextTokenId;
    string private _baseMetadataURI;

    /// @notice Maps each Helmet Token ID to its strictly verified Parent Armor Token ID.
    mapping(uint256 => uint256) public parentTokenIds;

    ////////////////////////////////////////////////////////////////
    // CUSTOM ERRORS
    ////////////////////////////////////////////////////////////////
    error InvalidBaseURI();
    error InvalidParentAddress();
    error MaxSupplyReached();
    error TokenDoesNotExist();
    error ParentTokenNotOwnedByCaller();
    error ParentTokenDoesNotExist();

    ////////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////////
    event HelmetMinted(address indexed to, uint256 indexed tokenId, uint256 indexed linkedArmorId);
    event BaseURIUpdated(string newBaseURI);

    ////////////////////////////////////////////////////////////////
    // CONSTRUCTOR
    ////////////////////////////////////////////////////////////////

    /**
     * @param baseURI_ The IPFS folder CID for Helmet metadata (ending with a trailing slash).
     * @param royaltyReceiver_ The address authorized to collect secondary sales royalties.
     * @param royaltyFeeNumerator_ Fee in basis points (e.g., 500 for 5%).
     * @param parentArmorContract_ The address of the deployed ArmorNFT contract.
     */
    constructor(
        string memory baseURI_,
        address royaltyReceiver_,
        uint96 royaltyFeeNumerator_,
        address parentArmorContract_
    ) 
        ERC721("Dragon Helmet", "DHELMET") 
        Ownable(msg.sender) 
    {
        if (bytes(baseURI_).length == 0) revert InvalidBaseURI();
        if (parentArmorContract_ == address(0)) revert InvalidParentAddress();
        
        _baseMetadataURI = baseURI_;
        parentArmorContract = parentArmorContract_;

        _setDefaultRoyalty(royaltyReceiver_, royaltyFeeNumerator_);
    }

    ////////////////////////////////////////////////////////////////
    // HIERARCHICAL MINT LOGIC
    ////////////////////////////////////////////////////////////////

    /**
     * @notice Mints a new Helmet NFT bound directly to an owned Armor NFT.
     * @param to The receiver wallet address.
     * @param armorTokenId The parent Armor ID that the receiver must currently own.
     */
    function mint(address to, uint256 armorTokenId) external onlyOwner returns (uint256) {
        uint256 currentTokenId = _nextTokenId;
        if (currentTokenId >= MAX_SUPPLY) revert MaxSupplyReached();

        // CROSS-CONTRACT CALL: Verify recipient owns the target Parent Armor Token
        try IParentArmor(parentArmorContract).ownerOf(armorTokenId) returns (address armorOwner) {
            if (armorOwner != to) revert ParentTokenNotOwnedByCaller();
        } catch {
            revert ParentTokenDoesNotExist();
        }

        // Structural binding storage mapping
        parentTokenIds[currentTokenId] = armorTokenId;

        unchecked {
            _nextTokenId = currentTokenId + 1;
        }

        _safeMint(to, currentTokenId);

        emit HelmetMinted(to, currentTokenId, armorTokenId);
        
        return currentTokenId;
    }

    ////////////////////////////////////////////////////////////////
    // METADATA & UTILITIES
    ////////////////////////////////////////////////////////////////

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); 
        return string(abi.encodePacked(_baseMetadataURI, tokenId.toString(), ".json"));
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        if (bytes(newBaseURI).length == 0) revert InvalidBaseURI();
        _baseMetadataURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    function baseURI() external view returns (string memory) {
        return _baseMetadataURI;
    }

    function setRoyaltyInfo(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    ////////////////////////////////////////////////////////////////
    // PAUSABLE CONTROLS
    ////////////////////////////////////////////////////////////////

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    ////////////////////////////////////////////////////////////////
    // REQUIRED OVERRIDES (OpenZeppelin 5.x)
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