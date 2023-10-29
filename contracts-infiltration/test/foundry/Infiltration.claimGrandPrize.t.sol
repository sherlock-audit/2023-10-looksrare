// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import {IInfiltration} from "../../contracts/interfaces/IInfiltration.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract Infiltration_ClaimGrandPrize_Test is TestHelpers {
    function setUp() public {
        _forkMainnet();
        _deployInfiltration();
        _setMintPeriod();
    }

    function test_claimGrandPrize() public {
        _downTo1ActiveAgent();

        IInfiltration.Agent memory agent = infiltration.getAgent(1);
        address winner = _ownerOf(agent.agentId);

        expectEmitCheckAll();
        emit PrizeClaimed(agent.agentId, address(0), 425 ether);

        vm.prank(winner);
        infiltration.claimGrandPrize();

        assertEq(winner.balance, 425 ether);
        assertEq(address(infiltration).balance, 0);

        (, , , , , , , , uint256 prizePool, , ) = infiltration.gameInfo();
        assertEq(prizePool, 0);

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_claimGrandPrize_RevertIf_NothingToClaim() public {
        _downTo1ActiveAgent();

        IInfiltration.Agent memory agent = infiltration.getAgent(1);
        address winner = _ownerOf(agent.agentId);

        vm.prank(winner);
        infiltration.claimGrandPrize();

        vm.prank(winner);
        vm.expectRevert(IInfiltration.NothingToClaim.selector);
        infiltration.claimGrandPrize();

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_claimGrandPrize_RevertIf_GameIsStillRunning() public {
        _downTo50ActiveAgents();
        _downToXActiveAgent(2);

        IInfiltration.Agent memory agent = infiltration.getAgent(1);
        address winner = _ownerOf(agent.agentId);

        vm.prank(winner);
        vm.expectRevert(IInfiltration.GameIsStillRunning.selector);
        infiltration.claimGrandPrize();

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_claimGrandPrize_RevertIf_NotAgentOwner() public {
        _downTo1ActiveAgent();

        IInfiltration.Agent memory agent = infiltration.getAgent(2);
        address loser = _ownerOf(agent.agentId);

        vm.prank(loser);
        vm.expectRevert(IInfiltration.NotAgentOwner.selector);
        infiltration.claimGrandPrize();

        invariant_totalAgentsIsEqualToTotalSupply();
    }
}
