// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Multisig Wallet Contract
 * @dev Implements a multi-signature wallet where transactions require a specified number of approvals
 */
contract Multisig {
    /// @notice List of signers
    address[] public signers;

    /// @notice Mapping to check if an address is a signer
    mapping(address => bool) public isSigner;

    /// @notice Minimum number of confirmations required for a transaction
    uint8 public requiredConfirmations;

    /// @dev Structure representing a transaction
    struct Transaction {
        address to; // Recipient address
        uint256 value; // Ether value to send
        bytes data; // Data payload
        uint8 confirmations; // Number of confirmations
        bool executed; // Whether the transaction has been executed
        mapping(address => bool) isConfirmed; // Mapping of addresses that confirmed the transaction
    }

    /// @notice List of all transactions
    Transaction[] public transactions;

    /// @dev Event emitted when a transaction is submitted
    event TransactionSubmitted(uint256 indexed txIndex, address indexed to, uint256 value, bytes data);

    /// @dev Event emitted when a transaction is confirmed
    event TransactionConfirmed(uint256 indexed txIndex, address indexed signer);

    /// @dev Event emitted when a transaction confirmation is removed
    event TransactionRemoved(uint256 indexed txIndex, address indexed signer);

    /// @dev Event emitted when a transaction is executed
    event TransactionExecuted(uint256 indexed txIndex);

    /// @dev Event emitted when a signer is added
    event SignerAdded(address indexed signer);

    /// @dev Event emitted when a signer is removed
    event SignerRemoved(address indexed signer);

    /// @notice Ensures that the caller is a signer
    modifier onlySigner() {
        require(isSigner[msg.sender], "Not a signer");
        _;
    }

    /**
     * @notice Constructor to initialize the multisig wallet
     * @param _signers List of initial signers
     * @param _requiredConfirmations Number of confirmations required for a transaction
     */
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

    /**
     * @notice Submit a transaction for approval
     * @param to Address of the recipient
     * @param value Amount of Ether to send
     * @param data Data payload of the transaction
     */
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

    /**
     * @notice Confirm a transaction
     * @param txIndex Index of the transaction to confirm
     */
    function confirmTransaction(uint256 txIndex) public onlySigner {
        require(txIndex < transactions.length, "Transaction does not exist");
        Transaction storage transaction = transactions[txIndex];
        require(!transaction.isConfirmed[msg.sender], "Transaction already confirmed");
        require(!transaction.executed, "Transaction already executed");

        transaction.isConfirmed[msg.sender] = true;
        transaction.confirmations++;

        emit TransactionConfirmed(txIndex, msg.sender);
    }

    /**
     * @notice Remove a confirmation for a transaction
     * @param txIndex Index of the transaction to remove confirmation for
     */
    function removeConfirmation(uint256 txIndex) public onlySigner {
        require(txIndex < transactions.length, "Transaction does not exist");
        Transaction storage transaction = transactions[txIndex];
        require(transaction.isConfirmed[msg.sender], "Transaction not confirmed");
        require(!transaction.executed, "Transaction already executed");

        transaction.isConfirmed[msg.sender] = false;
        transaction.confirmations--;

        emit TransactionRemoved(txIndex, msg.sender);
    }

    /**
     * @notice Execute a transaction
     * @param txIndex Index of the transaction to execute
     */
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

    /**
     * @notice Add a new signer to the wallet
     * @param newSigner Address of the new signer
     */
    function addSigner(address newSigner) public onlySigner {
        require(newSigner != address(0), "Invalid signer");
        require(!isSigner[newSigner], "Signer already exists");
        require(signers.length + 1 >= 3, "At least 3 signers required");

        isSigner[newSigner] = true;
        signers.push(newSigner);

        emit SignerAdded(newSigner);
    }

    /**
     * @notice Remove a signer from the wallet
     * @param signerToRemove Address of the signer to remove
     */
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