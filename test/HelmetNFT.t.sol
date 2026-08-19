// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ArmorNFT} from "../contracts/Armor.sol";
import {HelmetNFT} from "../contracts/Helmet.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract HelmetNFTTest is Test {
    ArmorNFT public armor;
    HelmetNFT public helmet;

    address public owner = makeAddr("owner");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public royaltyReceiver = makeAddr("royaltyReceiver");

    string public constant ARMOR_URI = "ipfs://QmArmorHash/";
    string public constant HELMET_URI = "ipfs://QmHelmetHash/";
    uint96 public constant ROYALTY_BPS = 500;

    event HelmetMinted(address indexed to, uint256 indexed tokenId, uint256 indexed linkedArmorId);

    function setUp() public {
        vm.startPrank(owner);
        armor = new ArmorNFT(ARMOR_URI, royaltyReceiver, ROYALTY_BPS);
        helmet = new HelmetNFT(HELMET_URI, royaltyReceiver, ROYALTY_BPS, address(armor));
        vm.stopPrank();
    }

    function test_InitializationState() public view {
        assertEq(helmet.name(), "Dragon Helmet");
        assertEq(helmet.symbol(), "DHELMET");
        assertEq(helmet.owner(), owner);
        assertEq(helmet.parentArmorContract(), address(armor));
        assertEq(helmet.baseURI(), HELMET_URI);
    }

    function test_RevertIf_ZeroAddressParentInConstructor() public {
        vm.expectRevert(HelmetNFT.InvalidParentAddress.selector);
        new HelmetNFT(HELMET_URI, royaltyReceiver, ROYALTY_BPS, address(0));
    }

    function test_MintHelmetWhenParentArmorOwned() public {
        vm.prank(owner);
        uint256 armorId = armor.mint(user1);

        vm.expectEmit(true, true, true, false);
        emit HelmetMinted(user1, 0, armorId);

        vm.prank(owner);
        uint256 helmetId = helmet.mint(user1, armorId);

        assertEq(helmetId, 0);
        assertEq(helmet.ownerOf(0), user1);
        assertEq(helmet.parentTokenIds(helmetId), armorId);
    }

    function test_RevertIf_ParentTokenDoesNotExist() public {
        vm.prank(owner);
        vm.expectRevert(HelmetNFT.ParentTokenDoesNotExist.selector);
        helmet.mint(user1, 99);
    }

    function test_RevertIf_RecipientDoesNotOwnParentToken() public {
        vm.prank(owner);
        uint256 armorId = armor.mint(user1);

        vm.prank(owner);
        vm.expectRevert(HelmetNFT.ParentTokenNotOwnedByCaller.selector);
        helmet.mint(user2, armorId);
    }

    function test_RevertIf_MintExceedsMaxSupply() public {
        vm.startPrank(owner);

        for (uint256 i = 0; i < 100; i++) {
            armor.mint(user1);
        }

        for (uint256 i = 0; i < 100; i++) {
            helmet.mint(user1, i);
        }

        vm.expectRevert(HelmetNFT.MaxSupplyReached.selector);
        helmet.mint(user1, 0);

        vm.stopPrank();
    }

    function test_PausePreventsHelmetMintingAndTransfers() public {
        vm.startPrank(owner);
        uint256 armorId = armor.mint(user1);
        uint256 helmetId = helmet.mint(user1, armorId);

        helmet.pause();

        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        helmet.mint(user1, armorId);
        vm.stopPrank();

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        helmet.transferFrom(user1, user2, helmetId);
    }

    function test_BurnHelmet() public {
        vm.startPrank(owner);
        uint256 armorId = armor.mint(user1);
        uint256 helmetId = helmet.mint(user1, armorId);
        vm.stopPrank();

        vm.prank(user1);
        helmet.burn(helmetId);

        assertEq(helmet.balanceOf(user1), 0);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, helmetId));
        helmet.ownerOf(helmetId);
    }
}