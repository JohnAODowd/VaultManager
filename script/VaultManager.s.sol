// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {VaultManager} from "../src/VaultManager.sol";

contract VaultManagerScript is Script {
    VaultManager public vaultManager;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        vaultManager = new VaultManager();

        vm.stopBroadcast();
    }
}
