// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

error Unauthorised();
error InsufficentFunds();

contract VaultManager {

    // VAULT SHAPE:
    struct Vault {
        uint256 balance;
        address owner;
    }

    // DATA:
    Vault[] public vaults; // [VAULT-1, VAULT-2, VAULT-3, ...]

    mapping(address => uint256[]) public vaultsByOwner;
    // {
    //    0x000001 -> [0],        // 0x00001 "owns" Vault-1
    //    0x000002 -> [1, 2],     // 0x00002 "owns" Vault-2 and Vault-3
    //    ...
    // }

    // EVENTS:
    event VaultAdded(uint256 id, address owner);
    event VaultDeposit(uint256 id, address owner, uint256 amount);
    event VaultWithdraw(uint256 id, address owner, uint256 amount);
    event VaultTransfer(uint256 id, address oldOwner, address newOwner);


    // MODIFIERS & FUNCTIONS:
    modifier onlyOwner(uint256 _vaultId) {
        if (vaults[_vaultId].owner != msg.sender) {
            revert Unauthorised();
        }

        _; // go ahead with the rest of the function as normal
    }

    function addVault() public returns (uint256 vaultIndex) {

        // 1. Create a Vault struct.
        // 2. Store this vault in the array.
        vaults.push(Vault({
            balance: 0,
            owner: msg.sender
        }));

        // 3. Create the vault mapping.
        vaultIndex = vaults.length - 1;

        vaultsByOwner[msg.sender].push(vaultIndex);

        // 4. Emit a VaultAdded event.
        emit VaultAdded(vaultIndex, msg.sender);

    }

    function deposit(uint256 _vaultId) payable public onlyOwner(_vaultId) {
        
        // 1. Deposit the funds.
        uint256 amount = msg.value;
        vaults[_vaultId].balance += amount;

        // 2. Emit a VaultDeposit event.
        emit VaultDeposit(_vaultId, msg.sender, amount);

    }

    function withdraw(uint256 _vaultId, uint256 amount) public onlyOwner(_vaultId) {
        
        // 1. Check the vault has sufficent funds.
        if (vaults[_vaultId].balance < amount) {
            revert InsufficentFunds();
        }

        // 2. Remove the funds from the vault.
        vaults[_vaultId].balance -= amount;

        // 3. Make the withdrawal.
        payable(vaults[_vaultId].owner).transfer(amount);

        // 4. Emit a VaultWithdraw event.
        emit VaultWithdraw(_vaultId, msg.sender, amount);

    }

    function getVault(uint256 _vaultId) public view returns (address owner, uint256 balance) {
        owner = vaults[_vaultId].owner;
        balance = vaults[_vaultId].balance;
    }

    function getVaultsLength() public view returns (uint256) {
        return vaults.length;
    }

    function getMyVaults() public view returns (uint256[] memory) {
        return vaultsByOwner[msg.sender];
    }

    function transferOwnership(uint256 _vaultId, address _newOwner) public onlyOwner(_vaultId) {

        // 1. Remove the vault in the old owner mapping.

        // Iterate through the owner's vaults.
        for (uint256 i; i<vaultsByOwner[msg.sender].length; i++) {

            // Check if the vault matches the owner's vault.
            if ( uint256(vaultsByOwner[msg.sender][i]) == _vaultId ) {
                // Found vault to be removed.

                // Replace the vault with the last vault.
                vaultsByOwner[msg.sender][i] = vaultsByOwner[msg.sender][vaultsByOwner[msg.sender].length - 1];

                // Remove the last vault.
                vaultsByOwner[msg.sender].pop();

                // Finished, exit loop.
                break;
            }
        }

        // 2. Add the new owner mapping.
        vaultsByOwner[_newOwner].push(_vaultId);

        // 3. Update the owner the in vault array.
        vaults[_vaultId].owner = _newOwner;

        // 4. Emit a VaultTransfer event.
        emit VaultTransfer(_vaultId, msg.sender, _newOwner);

    }

}