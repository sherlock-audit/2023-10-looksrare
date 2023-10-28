// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";

// Core contracts
import {InfiltrationPeriphery} from "../contracts/InfiltrationPeriphery.sol";
import {IQuoterV2} from "../contracts/interfaces/IQuoterV2.sol";

import {console2} from "../lib/forge-std/src/console2.sol";

contract PeripheryTest is Script {
    function run() external {
        // InfiltrationPeriphery periphery = InfiltrationPeriphery(payable(0x0cce1CF3aC72d0494EF6e1AbAb8e08ac3ac75495));

        uint256[] memory agentIds = new uint256[](1);
        agentIds[0] = 222;

        // vm.startBroadcast(deployerPrivateKey);
        IQuoterV2.QuoteExactOutputSingleParams memory params = IQuoterV2.QuoteExactOutputSingleParams({
            tokenIn: 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14,
            tokenOut: 0xa68c2CaA3D45fa6EBB95aA706c70f49D3356824E,
            amount: 50 ether,
            fee: uint24(3000),
            sqrtPriceLimitX96: uint160(0)
        });
        (uint256 costToHealInETH, , , ) = IQuoterV2(0xEd1f6473345F45b75F8179591dd5bA1888cf2FB3).quoteExactOutputSingle(
            params
        );

        // Mainnet
        // (uint256 costToHealInETH, , , ) = IQuoterV2(0x61fFE014bA17989E743c5F6cB21bF9697530B21e).quoteExactOutputSingle({
        //     tokenIn: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
        //     tokenOut: 0xf4d2888d29D722226FafA5d9B24F9164c092421E,
        //     fee: uint24(3000),
        //     amountOut: 50 ether,
        //     sqrtPriceLimitX96: 0
        // });
        console2.log("Cost to heal is ", costToHealInETH);
    }
}
