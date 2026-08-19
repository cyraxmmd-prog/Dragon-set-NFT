// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ArmorNFT} from "../contracts/Armor.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract ArmorNFTTest is Test {
    ArmorNFT public armor;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");
    address public royaltyReceiver = makeAddr("royaltyReceiver");

    string public constant BASE_URI = "ipfs://QmInitialHash/";
    string public constant NEW_BASE_URI = "ipfs://QmUpdatedHash/";
    uint96 public constant ROYALTY_BPS = 500; // 5%

    event ArmorMinted(address indexed to, uint256 indexed tokenId);
    event BaseURIUpdated(string newBaseURI);

    function setUp() public {
        vm.prank(owner);
        armor = new ArmorNFT(BASE_URI, royaltyReceiver, ROYALTY_BPS);
    }

    /* ================= INITIALIZATION TESTS ================= */

    function test_InitializationState() public view {
        assertEq(armor.name(), "Dragon Armor");
        assertEq(armor.symbol(), "DARMOR");
        assertEq(armor.owner(), owner);
        assertEq(armor.baseURI(), BASE_URI);
        assertEq(armor.MAX_SUPPLY(), 100);

        (address receiver, uint256 amount) = armor.royaltyInfo(0, 10000);
        assertEq(receiver, royaltyReceiver);
        assertEq(amount, 500); // 5% of 10000
    }

    function test_RevertIf_ZeroLengthBaseURIInConstructor() public {
        vm.expectRevert(ArmorNFT.InvalidBaseURI.selector);
        new ArmorNFT("", royaltyReceiver, ROYALTY_BPS);
    }

    /* ================= MINTING TESTS ================= */

    function test_OwnerCanMintSuccessfully() public {
        vm.expectEmit(true, true, false, false);
        emit ArmorMinted(user, 0);

        vm.prank(owner);
        uint256 tokenId = armor.mint(user);

        assertEq(tokenId, 0);
        assertEq(armor.ownerOf(0), user);
        assertEq(armor.balanceOf(user), 1);
        assertEq(armor.tokenURI(0), string(abi.encodePacked(BASE_URI, "0.json")));
    }

    function test_RevertIf_NonOwnerMints() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user));
        armor.mint(user);
    }

    function test_RevertIf_MintExceedsMaxSupply() public {
        vm.startPrank(owner);
        for (uint256 i = 0; i < 100; i++) {
            armor.mint(user);
        }

        vm.expectRevert(ArmorNFT.MaxSupplyReached.selector);
        armor.mint(user);
        vm.stopPrank();
    }

    /* ================= METADATA & URI TESTS ================= */

    function test_SetBaseURIByOwner() public {
        vm.expectEmit(false, false, false, true);
        emit BaseURIUpdated(NEW_BASE_URI);

        vm.prank(owner);
        armor.setBaseURI(NEW_BASE_URI);

        assertEq(armor.baseURI(), NEW_BASE_URI);
    }

    function test_RevertIf_SetEmptyBaseURI() public {
        vm.prank(owner);
        vm.expectRevert(ArmorNFT.InvalidBaseURI.selector);
        armor.setBaseURI("");
    }

    function test_RevertIf_TokenURIForNonExistentToken() public {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 99));
        armor.tokenURI(99);
    }

    /* ================= PAUSABLE & EMERGENCY TESTS ================= */

    function test_PauseBlocksTransfersAndMints() public {
        vm.prank(owner);
        armor.mint(user);

        vm.prank(owner);
        armor.pause();

        // Minting should revert when paused
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        armor.mint(user);

        // Transferring should revert when paused
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        armor.transferFrom(user, owner, 0);
    }

    function test_UnpauseRestoresFunctionality() public {
        vm.startPrank(owner);
        armor.pause();
        armor.unpause();

        uint256 tokenId = armor.mint(user);
        assertEq(tokenId, 0);
        vm.stopPrank();
    }

    /* ================= BURNING & ROYALTIES TESTS ================= */

    function test_TokenHolderCanBurnToken() public {
        vm.prank(owner);
        armor.mint(user);

        vm.prank(user);
        armor.burn(0);

        assertEq(armor.balanceOf(user), 0);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 0));
        armor.ownerOf(0);
    }

    function test_UpdateRoyaltyInfo() public {
        address newReceiver = makeAddr("newReceiver");
        vm.prank(owner);
        armor.setRoyaltyInfo(newReceiver, 1000); // 10%

        (address receiver, uint256 amount) = armor.royaltyInfo(0, 1000);
        assertEq(receiver, newReceiver);
        assertEq(amount, 100);
    }

    /* ================= INTERFACE COMPLIANCE ================= */

    function test_SupportsInterfaces() public view {
        assertTrue(armor.supportsInterface(0x80ac58cd)); // ERC721
        assertTrue(armor.supportsInterface(0x2a55205a)); // ERC2981
    }
}