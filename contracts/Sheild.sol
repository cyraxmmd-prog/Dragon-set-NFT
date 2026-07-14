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
 * @title ShieldNFT
 * @author Mohammad Hossein Ghiasvand
 * @notice Layer 5 Ultimate NFT contract linked structurally to MoonlightSwordNFT.
 * @dev Optimised for compilation layout in Remix; interface is placed at the bottom.
 */
contract ShieldNFT is ERC721, ERC721Burnable, ERC721Pausable, ERC2981, Ownable {
    using Strings for uint256;

    ////////////////////////////////////////////////////////////////
    // CONSTANTS & STORAGE
    ////////////////////////////////////////////////////////////////

    uint256 public constant MAX_SUPPLY = 100;
    
    /// @notice The immutable contract address of the parent MoonlightSwordNFT.
    address public immutable parentMoonlightContract;

    uint256 private _nextTokenId;
    string private _baseMetadataURI;

    /// @notice Maps each Shield Token ID to its strictly verified Parent Moonlight Sword Token ID.
    mapping(uint256 => uint256) public parentTokenIds;

    ////////////////////////////////////////////////////////////////
    // CUSTOM ERRORS
    ////////////////////////////////////////////////////////////////
    error InvalidBaseURI();
    error InvalidParentAddress();
    error MaxSupplyReached();
    error ParentTokenNotOwnedByCaller();
    error ParentTokenDoesNotExist();

    ////////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////////
    event ShieldMinted(address indexed to, uint256 indexed tokenId, uint256 indexed linkedMoonlightId);
    event BaseURIUpdated(string newBaseURI);

    ////////////////////////////////////////////////////////////////
    // CONSTRUCTOR
    ////////////////////////////////////////////////////////////////

    /**
     * @param baseURI_ The IPFS folder CID for Shield metadata (ending with a trailing slash).
     * @param royaltyReceiver_ The address authorized to collect secondary sales royalties.
     * @param royaltyFeeNumerator_ Fee in basis points (e.g., 500 for 5%).
     * @param parentMoonlightContract_ The address of the deployed MoonlightSwordNFT contract.
     */
    constructor(
        string memory baseURI_,
        address royaltyReceiver_,
        uint96 royaltyFeeNumerator_,
        address parentMoonlightContract_
    ) 
        ERC721("Dragon Aegis Shield", "DSHIELD") 
        Ownable(msg.sender) 
    {
        if (bytes(baseURI_).length == 0) revert InvalidBaseURI();
        if (parentMoonlightContract_ == address(0)) revert InvalidParentAddress();
        
        _baseMetadataURI = baseURI_;
        parentMoonlightContract = parentMoonlightContract_;

        _setDefaultRoyalty(royaltyReceiver_, royaltyFeeNumerator_);
    }

    ////////////////////////////////////////////////////////////////
    // HIERARCHICAL MINT LOGIC
    ////////////////////////////////////////////////////////////////

    /**
     * @notice Mints a new Shield NFT bound directly to an owned Moonlight Sword NFT.
     * @param to The receiver wallet address.
     * @param moonlightTokenId The parent Moonlight Sword ID that the receiver must currently own.
     */
    function mint(address to, uint256 moonlightTokenId) external onlyOwner returns (uint256) {
        uint256 currentTokenId = _nextTokenId;
        if (currentTokenId >= MAX_SUPPLY) revert MaxSupplyReached();

        // CROSS-CONTRACT CALL: Verify recipient owns the target Parent Moonlight Sword Token
        try IParentMoonlight(parentMoonlightContract).ownerOf(moonlightTokenId) returns (address moonlightOwner) {
            if (moonlightOwner != to) revert ParentTokenNotOwnedByCaller();
        } catch {
            revert ParentTokenDoesNotExist();
        }

        // Structural binding storage mapping
        parentTokenIds[currentTokenId] = moonlightTokenId;

        unchecked {
            _nextTokenId = currentTokenId + 1;
        }

        _safeMint(to, currentTokenId);

        emit ShieldMinted(to, currentTokenId, moonlightTokenId);
        
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

////////////////////////////////////////////////////////////////
// INTERFACE (Placed at the bottom to ensure correct Remix compilation)
////////////////////////////////////////////////////////////////
interface IParentMoonlight {
    function ownerOf(uint256 tokenId) external view returns (address);
}