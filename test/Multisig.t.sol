// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "src/Multisig.sol";

contract MultisigTest is Test {
    Multisig public multisig;
    address[] public initialSigners;

    address public signer1 = address(0x1);
    address public signer2 = address(0x2);
    address public signer3 = address(0x3);
    address public nonSigner = address(0x4);

    function setUp() public {
        initialSigners = [signer1, signer2, signer3];
        multisig = new Multisig(initialSigners, 2);
    }

    function testDeployment() public view {
        assertEq(multisig.requiredConfirmations(), 2);
        assertEq(multisig.signers(0), signer1);
        assertEq(multisig.signers(1), signer2);
        assertEq(multisig.signers(2), signer3);
        assertTrue(multisig.isSigner(signer1));
        assertTrue(multisig.isSigner(signer2));
        assertTrue(multisig.isSigner(signer3));
        assertFalse(multisig.isSigner(nonSigner));
    }

    function testSubmitTransaction() public {
        vm.prank(signer1);
        multisig.submitTransaction(address(0x5), 1 ether, "0x");

        (address to, uint256 value, , , bool executed) = multisig.transactions(0);
        assertEq(to, address(0x5));
        assertEq(value, 1 ether);
        assertFalse(executed);
    }

    function testConfirmTransaction() public {
        vm.prank(signer1);
        multisig.submitTransaction(address(0x5), 1 ether, "0x");

        vm.prank(signer1);
        multisig.confirmTransaction(0);

        (, , , uint8 confirmations, ) = multisig.transactions(0);
        assertEq(confirmations, 1);
    }

    function testRemoveConfirmation() public {
        vm.prank(signer1);
        multisig.submitTransaction(address(0x5), 1 ether, "0x");

        vm.prank(signer1);
        multisig.confirmTransaction(0);

        vm.prank(signer1);
        multisig.removeConfirmation(0);

        (, , , uint8 confirmations, ) = multisig.transactions(0);
        assertEq(confirmations, 0);
    }

    function testExecuteTransaction() public {
        vm.deal(address(multisig), 2 ether);
        assertEq(address(multisig).balance, 2 ether);

        vm.prank(signer1);
        multisig.submitTransaction(address(0x5), 1 ether, "");

        vm.prank(signer1);
        multisig.confirmTransaction(0);

        vm.prank(signer2);
        multisig.confirmTransaction(0);

        vm.prank(signer1);
        multisig.executeTransaction(0);

        (, , , , bool executed) = multisig.transactions(0);
        assertTrue(executed);
        assertEq(address(0x5).balance, 1 ether);
    }


    function testAddSigner() public {
        vm.prank(signer1);
        multisig.addSigner(address(0x6));

        assertTrue(multisig.isSigner(address(0x6)));
        assertEq(multisig.signers(3), address(0x6));
    }

    function testRemoveSigner() public {
        vm.prank(signer1);
        multisig.addSigner(address(0x6));

        assertTrue(multisig.isSigner(address(0x6)));

        vm.prank(signer1);
        multisig.removeSigner(signer3);

        assertFalse(multisig.isSigner(signer3));
        assertTrue(multisig.isSigner(address(0x6)));
    }

    function testFailSubmitTransactionNonSigner() public {
        vm.prank(nonSigner);
        multisig.submitTransaction(address(0x5), 1 ether, "0x");
    }

    function testFailAddSignerNonSigner() public {
        vm.prank(nonSigner);
        multisig.addSigner(address(0x6));
    }

    function testFailRemoveSignerBelowMinimum() public {
        vm.prank(signer1);
        multisig.removeSigner(signer3);

        vm.prank(signer2);
        multisig.removeSigner(signer2);
    }
}