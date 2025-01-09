// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "src/Multisig.sol";

contract MultisigScript is Script {
    Multisig public multisig;

    address public signer1 = vm.envAddress("SIGNER1");
    address public signer2 = vm.envAddress("SIGNER2");
    address public signer3 = vm.envAddress("SIGNER3");

    function run() public {
        vm.startBroadcast();

        address[] memory initialSigners = new address[](3);
        initialSigners[0] = signer1;
        initialSigners[1] = signer2;
        initialSigners[2] = signer3;

        multisig = new Multisig(initialSigners, 2);

        console.log("Multisig deployed at:", address(multisig));
        console.log("Signer 1:", signer1);
        console.log("Signer 2:", signer2);
        console.log("Signer 3:", signer3);

        vm.stopBroadcast();
    }
}