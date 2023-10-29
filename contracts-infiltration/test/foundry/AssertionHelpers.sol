// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721A} from "erc721a/contracts/IERC721A.sol";

import {Infiltration} from "../../contracts/Infiltration.sol";
import {IInfiltration} from "../../contracts/interfaces/IInfiltration.sol";

import {Test} from "../../lib/forge-std/src/Test.sol";

abstract contract AssertionHelpers is Test {
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
    event Killed(uint256 roundId, uint256[] agentIds);
    event HealRequestSubmitted(uint256 roundId, uint256[] agentIds, uint256[] costs);
    event PrizeClaimed(uint256 agentId, address currency, uint256 amount);
    event RandomnessRequested(uint256 roundId, uint256 requestId);
    event RoundStarted(uint256 roundId);
    event Won(uint256 roundId, uint256 agentId);

    Infiltration internal infiltration;

    function expectEmitCheckAll() internal {
        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
    }

    function _ownerOf(uint256 agentId) internal view returns (address agentOwner) {
        agentOwner = IERC721A(address(infiltration)).ownerOf(agentId);
    }

    function assertAgentIsTransferrable(uint256 agentId) internal {
        address agentOwner = _ownerOf(agentId);
        vm.prank(agentOwner);
        infiltration.transferFrom(agentOwner, address(69), agentId);
    }

    function assertAgentIsNotTransferrable(uint256 agentId, IInfiltration.AgentStatus status) internal {
        address agentOwner = _ownerOf(agentId);
        vm.expectRevert(abi.encodePacked(IInfiltration.InvalidAgentStatus.selector, abi.encode(agentId, status)));
        vm.prank(agentOwner);
        infiltration.transferFrom(agentOwner, address(69), agentId);
    }

    function assertAgentIdsAreHealing(uint256[] memory agentIds) internal {
        for (uint256 i; i < agentIds.length; i++) {
            IInfiltration.Agent memory agent = infiltration.getAgent(agentIds[i]);

            assertEq(agent.agentId, agentIds[i]);
            assertEq(uint8(agent.status), uint8(IInfiltration.AgentStatus.Healing));
            assertEq(agent.woundedAt, 1);
            assertEq(agent.healCount, 0);

            assertAgentIsNotTransferrable(agentIds[i], IInfiltration.AgentStatus.Healing);
        }
    }

    function invariant_totalAgentsIsEqualToTotalSupply() internal {
        (
            uint16 activeAgents,
            uint16 woundedAgents,
            uint16 healingAgents,
            uint16 deadAgents,
            uint16 escapedAgents,
            ,
            ,
            ,
            ,
            ,

        ) = infiltration.gameInfo();

        assertEq(infiltration.totalSupply(), 10_000);
        assertEq(
            infiltration.totalSupply(),
            activeAgents + woundedAgents + healingAgents + deadAgents + escapedAgents,
            "Invariant violation"
        );
    }
}
