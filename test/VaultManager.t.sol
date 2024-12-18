// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {VaultManager} from "../src/VaultManager.sol";

error Unauthorised();
error InsufficentFunds();

contract VaultManagerTest is Test {
    VaultManager public vaultManager;

    address public alice;
    address public bob;
    address public carol;

    // CALL THIS BEFORE EVERY TEST:
    function setUp() public {
        vaultManager = new VaultManager();
        alice = makeAddr("Alice");
        bob = makeAddr("Bob");
        carol = makeAddr("Carol");
    }

    function testInitial() public view {
        uint256 vaultsLength = vaultManager.getVaultsLength();
        assertEq(vaultsLength, 0);
    }

    function testSingleVault() public {
        // 1. ADD A VAULT TO THE VAULT MANAGER
        vm.prank(alice);
        uint256 vaultIndex = vaultManager.addVault();
        uint256 vaultLength = vaultManager.getVaultsLength();
        assertEq(vaultIndex, 0);
        assertEq(vaultLength, 1);

        // 2. CHECK ITS INITIAL STATUS
        (address owner, uint256 balance) = vaultManager.getVault(0);
        assertEq(owner, alice);
        assertEq(balance, 0);

        // 3. CHECK VAULT MAPPING
        vm.prank(alice);
        uint256[] memory aliceVaults = vaultManager.getMyVaults();

        uint256[] memory aliceCorrectVaults = new uint256[](1);
        aliceCorrectVaults[0] = 0;

        assertEq(aliceVaults, aliceCorrectVaults);
    }

    function testSadDeposit() public {
        // 1. ALICE CREATES A VAULT
        vm.prank(alice);
        vaultManager.addVault();

        // 2. GIVE BOB 10 ETH
        vm.deal(bob, 10 ether);
        uint256 bobBalance = bob.balance;
        assertEq(bobBalance, 10 ether);

        // 3. CONFIRM BOB CAN'T DEPOSIT 10 ETH INTO ALICE'S VAULT
        vm.prank(bob);
        bytes memory fnCall = abi.encodeWithSignature("deposit(uint256)", 0);
        (bool bobDepositOkay, ) = address(vaultManager).call{value: 10 ether}(fnCall);
        assertEq(bobDepositOkay, false);

        // 4. CHECK BOB STILL HAS 10 ETH
        assertEq(bob.balance, 10 ether);

        // 5. CHECK THE VAULT BALANCE REMAINS UNCHANGED
        (, uint256 balance) = vaultManager.getVault(0);
        assertEq(balance, 0);

    }

    function testHappyDeposit() public {
        // 1. ALICE CREATES A VAULT
        vm.prank(alice);
        vaultManager.addVault();

        // 2. GIVE ALICE 10 ETH
        vm.deal(alice, 10 ether);
        uint256 aliceBalance = alice.balance;
        assertEq(aliceBalance, 10 ether);

        // 3. CONFIRM ALICE CAN DEPOSIT 10 ETH
        vm.prank(alice);
        bytes memory fnCall = abi.encodeWithSignature("deposit(uint256)", 0);
        (bool aliceDepositOkay, ) = address(vaultManager).call{value: 10 ether}(fnCall);
        assertEq(aliceDepositOkay, true);

        // 4. CONFIRM ALICE NOW HAS 0 ETH
        assertEq(alice.balance, 0);

        // 5. CHECK THE VAULT BALANCE IS 10 ETH
        (, uint256 balance) = vaultManager.getVault(0);
        assertEq(balance, 10 ether);

    }

    function testHappyWithdraw() public {
        // 1. ALICE CREATES VAULT
        vm.prank(alice);
        vaultManager.addVault();

        // 2. GIVE ALICE 10 ETH
        vm.deal(alice, 10 ether);
        uint256 aliceBalance = alice.balance;
        assertEq(aliceBalance, 10 ether);

        // 2. ALICE DEPOSITS 10 ETH
        vm.prank(alice);
        bytes memory fnCall = abi.encodeWithSignature("deposit(uint256)", 0);
        (bool aliceDepositOkay, ) = address(vaultManager).call{value: 10 ether}(fnCall);
        assertEq(aliceDepositOkay, true);

        // 3. CONFIRM ALICE NOW HAS 0 ETH
        assertEq(alice.balance, 0);

        // 4. CONFIRM THE VAULT BALANCE IS 10 ETH
        (, uint256 balanceAfterDeposit) = vaultManager.getVault(0);
        assertEq(balanceAfterDeposit, 10 ether);

        // 5. CONFIRM ALICE CANNOT WITHDRAW MORE THAN HER BALANCE
        vm.prank(alice);
        vm.expectRevert(InsufficentFunds.selector);
        vaultManager.withdraw(0, 20 ether);

        // 6. CHECK THE VAULT BALANCE IS STILL 10 ETH
        (, uint256 balanceAfterFailedWitdraw) = vaultManager.getVault(0);
        assertEq(balanceAfterFailedWitdraw, 10 ether);

        // 7. CONFIRM ALICE STILL HAS 0 ETH
        assertEq(alice.balance, 0);

        // 8. ALICE WITHDRAWS 10 ETH
        vm.prank(alice);
        vaultManager.withdraw(0, 10 ether);

        // 9. CONFIRM ALICE NOW HAS 10 ETH
        assertEq(alice.balance, 10 ether);

        // 10. CONFIRM THE VAULT NOW HAS 0 ETH
        (, uint256 balanceAfterWithdraw) = vaultManager.getVault(0);
        assertEq(balanceAfterWithdraw, 0);


    }

    function testSadWithdraw() public {
        // 1. ALICE CREATES VAULT
        vm.prank(alice);
        vaultManager.addVault();

        // 2. GIVE ALICE 10 ETH
        vm.deal(alice, 10 ether);
        uint256 aliceBalance = alice.balance;
        assertEq(aliceBalance, 10 ether);

        // 2. ALICE DEPOSITS 10 ETH
        vm.prank(alice);
        bytes memory fnCall = abi.encodeWithSignature("deposit(uint256)", 0);
        (bool aliceDepositOkay, ) = address(vaultManager).call{value: 10 ether}(fnCall);
        assertEq(aliceDepositOkay, true);

        // 3. CONFIRM ALICE NOW HAS 0 ETH
        assertEq(alice.balance, 0);

        // 4. CONFIRM THE VAULT BALANCE IS 10 ETH
        (, uint256 balanceAfterDeposit) = vaultManager.getVault(0);
        assertEq(balanceAfterDeposit, 10 ether);

        // 5. CONFIRM BOB CANNOT WITHDRAW FROM ALICE'S VAULT
        vm.prank(bob);
        vm.expectRevert(Unauthorised.selector);
        vaultManager.withdraw(0, 10 ether); 

        // 3. CONFIRM BOB STILL HAS 0 ETH
        assertEq(bob.balance, 0);

        // 3. CONFIRM ALICE STILL HAS 0 ETH
        assertEq(alice.balance, 0);

        // 4. CONFIRM THE VAULT BALANCE IS STILL 10 ETH
        (, uint256 balanceAfterFailedWithdraw) = vaultManager.getVault(0);
        assertEq(balanceAfterFailedWithdraw, 10 ether);
    }



    function testMutipleVaults() public {
        // 1. ALICE CREATES VAULT
        vm.prank(alice);
        vaultManager.addVault();

        // 2. BOB CREATES VAULT
        vm.prank(bob);
        vaultManager.addVault();

        // 3. ALICE CREATES ANOTHER VAULT
        vm.prank(alice);
        vaultManager.addVault();

        // 4. CHECK THERE ARE THREE VAULTS
        uint256 vaultsLength = vaultManager.getVaultsLength();
        assertEq(vaultsLength, 3);

        // 5. VERIFY THAT ALICE HAS 2 VAULTS
        vm.prank(alice);
        uint256[] memory aliceVaults = vaultManager.getMyVaults();
        uint256 aliceVaultsLength = aliceVaults.length;
        assertEq(aliceVaultsLength, 2);

        // 6. VERIFY THAT BOB HAS 1 VAULT
        vm.prank(bob);
        uint256[] memory bobVaults = vaultManager.getMyVaults();
        uint256 bobVaultsLength = bobVaults.length;
        assertEq(bobVaultsLength, 1);

        // 5. VERIFY ALICE OWNER MAPPING
        uint256[] memory aliceCorrectVaults = new uint256[](2);
        aliceCorrectVaults[0] = 0; // First Vault
        aliceCorrectVaults[1] = 2; // Third Vault
        assertEq(aliceVaults , aliceCorrectVaults);

        // 5. VERIFY BOB OWNER MAPPING
        uint256[] memory bobCorrectVaults = new uint256[](1);
        bobCorrectVaults[0] = 1; // Second Vault
        assertEq(bobVaults, bobCorrectVaults);
    }

    function testTransferOwnership() public {
        // 1. ALICE CREATES VAULT
        vm.prank(alice);
        vaultManager.addVault();

        // 2. BOB CREATES VAULT
        vm.prank(bob);
        vaultManager.addVault();

        // 3. ALICE CREATES ANOTHER VAULT
        vm.prank(alice);
        vaultManager.addVault();

        // 4. BOB TRANSFERS HIS VAULT TO ALICE
        vm.prank(bob);
        vaultManager.transferOwnership(1, alice);

        // 5. VERIFY BOB CANNOT SEND HIS PREVIOUSLY OWNED VAULT AGAIN
        vm.prank(bob);
        vm.expectRevert(Unauthorised.selector);
        vaultManager.transferOwnership(1, alice);

        // 6. VERIFY THAT ALICE HAS 3 VAULTS
        vm.prank(alice);
        uint256[] memory aliceVaults = vaultManager.getMyVaults();
        uint256 aliceVaultsLength = aliceVaults.length;
        assertEq(aliceVaultsLength, 3);

        // 7. VERIFY ALICE OWNER MAPPING
        uint256[] memory aliceCorrectVaults = new uint256[](3);
        aliceCorrectVaults[0] = 0; // First Vault
        aliceCorrectVaults[1] = 2; // Third Vault
        aliceCorrectVaults[2] = 1; // Second Vault (was Bob's)
        assertEq(aliceVaults, aliceCorrectVaults);

        // 8. VERIFY BOB'S PREVIOUSLY OWNED VAULT ADDRESS WAS UPDATED TO ALICE'S ADDRESS
        (address bobPreviousVaultAddress, ) = vaultManager.getVault(1); // Second Vault (was Bob's)
        assertEq(bobPreviousVaultAddress, alice);

        // 9. VERIFY BOB HAS NO VAULTS
        uint256[] memory bobVaults = vaultManager.getMyVaults();
        uint256 bobVaultsLength = bobVaults.length;
        assertEq(bobVaultsLength, 0);

        // 10. VERIFY CAROL CANNOT TRANSFER BOB'S PREVIOUSLY OWNED VAULT BACK TO BOB
        vm.prank(carol);
        vm.expectRevert(Unauthorised.selector);
        vaultManager.transferOwnership(1, bob);

        // 11. VERIFY BOB CANNOT SEND HIS PREVIOUSLY OWNED VAULT TO CAROL
        vm.prank(bob);
        vm.expectRevert(Unauthorised.selector);
        vaultManager.transferOwnership(1, carol);

        // 12. VERIFY ALICE CANNOT TRANSFER A NON-EXISTENT VAULT
        vm.prank(alice);
        vm.expectRevert();
        vaultManager.transferOwnership(999, bob);
    }
}