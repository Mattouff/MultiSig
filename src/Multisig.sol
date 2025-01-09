// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Multisig {
    address[] public signers;
    mapping(address => bool) public isSigner;
    uint8 public requiredConfirmations;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        uint8 confirmations;
        bool executed;
        mapping(address => bool) isConfirmed;
    }

    Transaction[] public transactions;

    event TransactionSubmitted(uint256 indexed txIndex, address indexed to, uint256 value, bytes data);
    event TransactionConfirmed(uint256 indexed txIndex, address indexed signer);
    event TransactionRevoked(uint256 indexed txIndex, address indexed signer);
    event TransactionExecuted(uint256 indexed txIndex);
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);

    modifier onlySigner() {
        require(isSigner[msg.sender], "Not a signer");
        _;
    }

    constructor(address[] memory _signers, uint8 _requiredConfirmations) {
        require(_signers.length >= 3, "At least 3 signers required");
        require(
            _requiredConfirmations >= 2 && _requiredConfirmations <= _signers.length,
            "Invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            require(signer != address(0), "Invalid signer");
            require(!isSigner[signer], "Signer not unique");

            isSigner[signer] = true;
            signers.push(signer);
        }

        requiredConfirmations = _requiredConfirmations;
    }

    function submitTransaction(
        address to,
        uint256 value,
        bytes memory data
    ) public onlySigner {
        transactions.push();
        uint256 txIndex = transactions.length - 1;
        Transaction storage transaction = transactions[txIndex];
        transaction.to = to;
        transaction.value = value;
        transaction.data = data;
        transaction.confirmations = 0;
        transaction.executed = false;

        emit TransactionSubmitted(txIndex, to, value, data);
    }

    function confirmTransaction(uint256 txIndex) public onlySigner {
        require(txIndex < transactions.length, "Transaction does not exist");
        Transaction storage transaction = transactions[txIndex];
        require(!transaction.isConfirmed[msg.sender], "Transaction already confirmed");
        require(!transaction.executed, "Transaction already executed");

        transaction.isConfirmed[msg.sender] = true;
        transaction.confirmations++;

        emit TransactionConfirmed(txIndex, msg.sender);
    }

    function removeConfirmation(uint256 txIndex) public onlySigner {
        require(txIndex < transactions.length, "Transaction does not exist");
        Transaction storage transaction = transactions[txIndex];
        require(transaction.isConfirmed[msg.sender], "Transaction not confirmed");
        require(!transaction.executed, "Transaction already executed");

        transaction.isConfirmed[msg.sender] = false;
        transaction.confirmations--;

        emit TransactionRevoked(txIndex, msg.sender);
    }

    function executeTransaction(uint256 txIndex) public onlySigner {
        require(txIndex < transactions.length, "Transaction does not exist");
        Transaction storage transaction = transactions[txIndex];
        require(transaction.confirmations >= requiredConfirmations, "Not enough confirmations");
        require(!transaction.executed, "Transaction already executed");

        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Transaction failed");

        emit TransactionExecuted(txIndex);
    }

    function addSigner(address newSigner) public onlySigner {
        require(newSigner != address(0), "Invalid signer");
        require(!isSigner[newSigner], "Signer already exists");
        require(signers.length + 1 >= 3, "At least 3 signers required");

        isSigner[newSigner] = true;
        signers.push(newSigner);

        emit SignerAdded(newSigner);
    }

    function removeSigner(address signerToRemove) public onlySigner {
        require(isSigner[signerToRemove], "Not a signer");
        require(signers.length - 1 >= 3, "At least 3 signers required");

        isSigner[signerToRemove] = false;

        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == signerToRemove) {
                signers[i] = signers[signers.length - 1];
                signers.pop();
                break;
            }
        }

        emit SignerRemoved(signerToRemove);
    }
}