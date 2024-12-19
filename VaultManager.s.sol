// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// CONTRACT ADDRESS: 0xa0AA9C3E560ff87E6DFf40cD0a0be3d5cA1E514E
// https://sepolia.etherscan.io/address/0xa0AA9C3E560ff87E6DFf40cD0a0be3d5cA1E514E

import {Script, console} from "forge-std/Script.sol";
import {VaultManager} from "../src/VaultManager.sol";

contract VaultManagerScript is Script {
    VaultManager public vaultManager;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        vaultManager = new VaultManager();

        vm.stopBroadcast();
    }
}