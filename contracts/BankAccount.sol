// SPDX-License-Identifier: MIT
pragma solidity  0.8.30;

contract BankAccount {
    // struct DepositTransaction {
    //     address sender;
    //     uint256 amount;
    //     uint256 timestamp;
    // }

    //polja koja zelim da vratim korisniku; bolji su event(logovi) nego strukture
    event Deposit(address indexed sender, uint256 amount, uint256 timestamp);
    uint256 balance;
    address public owner; //uvek je 20 bajtova; public zapravo kaze da smo kao napravili i konstruktor

    //DepositTransaction[] depositTransaction;

    receive() external payable {
        balance += msg.value;
        // depositTransaction.push(DepositTransaction({
        //     sender: msg.sender,
        //     amount: msg.value,
        //     timestamp: block.timestamp
        // }));
        emit Deposit(msg.sender, msg.value, block.timestamp);
     }
    //moze da se posalje i adress initialOwner i da to bude owner; u ovom slucaju smo to mi(koji pravimo)
    constructor() {
        owner = msg.sender;
    }

    // function deposit() external payable  {
    //     balance += msg.value;
    //     //uint256 currentTimestamp = block.timestamp;
    // }

    //ovako saljemo pare na ownera
    function withdraw(uint256 amount) external {
        (bool sent, bytes memory data) = owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

}