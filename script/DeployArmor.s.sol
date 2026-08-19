// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {ArmorNFT} from "../contracts/Armor.sol";

contract DeployArmor is Script {
    // Default deployment params for local / testnet environments
    string public constant INITIAL_BASE_URI = "ipfs://QmDragonArmorBaseHash/";
    uint96 public constant ROYALTY_FEE_BPS = 500; // 5%

    function run() external returns (ArmorNFT armor) {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying ArmorNFT with deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        armor = new ArmorNFT(
            INITIAL_BASE_URI,
            deployer, // Sets deployer as initial royalty receiver
            ROYALTY_FEE_BPS
        );

        vm.stopBroadcast();

        console.log("ArmorNFT deployed at:", address(armor));
    }
}