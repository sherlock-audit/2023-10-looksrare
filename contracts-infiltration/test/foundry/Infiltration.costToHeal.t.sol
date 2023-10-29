// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IInfiltration} from "../../contracts/interfaces/IInfiltration.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract Infiltration_CostToHeal_Test is TestHelpers {
    function setUp() public {
        _forkMainnet();
        _deployInfiltration();
    }

    function test_costToHeal() public {
        _stubAgentStatusAndHealCount(1, 0);
        _stubAgentStatusAndHealCount(2, 1);
        _stubAgentStatusAndHealCount(3, 2);
        _stubAgentStatusAndHealCount(4, 3);
        _stubAgentStatusAndHealCount(5, 4);
        _stubAgentStatusAndHealCount(6, 5);

        uint256[] memory agentIds = new uint256[](1);
        agentIds[0] = 1;
        assertEq(infiltration.costToHeal(agentIds), 50 ether);

        agentIds = new uint256[](2);
        agentIds[0] = 1;
        agentIds[1] = 2;
        assertEq(infiltration.costToHeal(agentIds), 150 ether);

        agentIds = new uint256[](3);
        agentIds[0] = 1;
        agentIds[1] = 2;
        agentIds[2] = 3;
        assertEq(infiltration.costToHeal(agentIds), 350 ether);

        agentIds = new uint256[](4);
        agentIds[0] = 1;
        agentIds[1] = 2;
        agentIds[2] = 3;
        agentIds[3] = 4;
        assertEq(infiltration.costToHeal(agentIds), 750 ether);

        agentIds = new uint256[](5);
        agentIds[0] = 1;
        agentIds[1] = 2;
        agentIds[2] = 3;
        agentIds[3] = 4;
        agentIds[4] = 5;
        assertEq(infiltration.costToHeal(agentIds), 1_550 ether);

        agentIds = new uint256[](6);
        agentIds[0] = 1;
        agentIds[1] = 2;
        agentIds[2] = 3;
        agentIds[3] = 4;
        agentIds[4] = 5;
        agentIds[5] = 6;
        assertEq(infiltration.costToHeal(agentIds), 3_150 ether);
    }

    function _stubAgentStatusAndHealCount(uint256 agentId, uint256 _healCount) private {
        uint256 agentsSlot = 15;
        uint256 agentStorageSlot;
        assembly {
            mstore(0x00, agentId) // agentId is the same as index in this scenario
            mstore(0x20, agentsSlot)
            agentStorageSlot := keccak256(0x00, 0x40)
        }

        uint256 statusOffset = 16;
        uint256 healCountOffset = 64;
        uint256 value = uint256(vm.load(address(infiltration), bytes32(agentStorageSlot)));

        value &= ~(uint256(0xffff) << healCountOffset);
        value |= uint256(_healCount) << healCountOffset;

        value &= ~(uint256(0xffff) << statusOffset);
        value |= uint256(uint8(IInfiltration.AgentStatus.Wounded)) << statusOffset;

        vm.store(address(infiltration), bytes32(agentStorageSlot), bytes32(value));

        IInfiltration.Agent memory agent = infiltration.getAgent(agentId);
        assertEq(uint8(agent.status), uint8(IInfiltration.AgentStatus.Wounded));
        assertEq(agent.healCount, _healCount);
    }
}
