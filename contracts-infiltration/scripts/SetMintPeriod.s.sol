// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";

// Core contracts
import {IInfiltration} from "../contracts/interfaces/IInfiltration.sol";

contract SetMintPeriod is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("TESTNET_KEY");
        IInfiltration infiltration = IInfiltration(0x02FCDB178Cc1e2Cf053BA1b8F7eF99D984C99Beb);

        uint40 mintStart = 0;
        uint40 mintEnd = uint40(block.timestamp + 3 hours);

        vm.startBroadcast(deployerPrivateKey);
        infiltration.setMintPeriod(mintStart, mintEnd);
        vm.stopBroadcast();
    }
}
