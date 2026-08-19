// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {ArmorNFT} from "../contracts/Armor.sol";
import {HelmetNFT} from "../contracts/Helmet.sol";

contract DeployHelmet is Script {
    string public constant HELMET_BASE_URI = "ipfs://QmDragonHelmetBaseHash/";
    string public constant ARMOR_BASE_URI = "ipfs://QmDragonArmorBaseHash/";
    uint96 public constant ROYALTY_FEE_BPS = 500; // 5%

    function run() external returns (ArmorNFT armor, HelmetNFT helmet) {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY", 
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying Ecosystem Contracts with deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Parent Armor NFT first
        armor = new ArmorNFT(ARMOR_BASE_URI, deployer, ROYALTY_FEE_BPS);
        console.log("Parent ArmorNFT Deployed at:", address(armor));

        // Deploy Child Helmet NFT linked to Parent Armor
        helmet = new HelmetNFT(
            HELMET_BASE_URI,
            deployer,
            ROYALTY_FEE_BPS,
            address(armor)
        );
        console.log("Child HelmetNFT Deployed at:", address(helmet));

        vm.stopBroadcast();
    }
}