// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";

// Core contracts
import {IInfiltration} from "../contracts/interfaces/IInfiltration.sol";

contract StartGame is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("TESTNET_KEY");
        IInfiltration infiltration = IInfiltration(0x02FCDB178Cc1e2Cf053BA1b8F7eF99D984C99Beb);

        vm.startBroadcast(deployerPrivateKey);
        infiltration.startGame();
        vm.stopBroadcast();
    }
}
