// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {IERC721A} from "erc721a/contracts/IERC721A.sol";

import {IInfiltration} from "../../contracts/interfaces/IInfiltration.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract Infiltration_FulfillRandomWords_Test is TestHelpers {
    event HealRequestFulfilled(uint256 roundId, IInfiltration.HealResult[] healResults);
    event Wounded(uint256 roundId, uint256[] agentIds);
    event InvalidRandomnessFulfillment(uint256 requestId, uint256 randomnessRequestRoundId, uint256 currentRoundId);

    function setUp() public {
        _forkMainnet();
        _deployInfiltration();
        _setMintPeriod();
    }

    function test_fulfillRandomWords_WoundRequestFulfilled() public {
        uint256[] memory randomWords = _randomWords();

        _mintOut();

        expectEmitCheckAll();
        emit RoundStarted(1);

        vm.prank(owner);
        infiltration.startGame();

        uint256[] memory woundedEventAgentIds = new uint256[](20);
        woundedEventAgentIds[0] = 9421;
        woundedEventAgentIds[1] = 3638;
        woundedEventAgentIds[2] = 177;
        woundedEventAgentIds[3] = 8591;
        woundedEventAgentIds[4] = 2609;
        woundedEventAgentIds[5] = 2556;
        woundedEventAgentIds[6] = 2288;
        woundedEventAgentIds[7] = 9708;
        woundedEventAgentIds[8] = 8139;
        woundedEventAgentIds[9] = 4521;
        woundedEventAgentIds[10] = 3061;
        woundedEventAgentIds[11] = 5621;
        woundedEventAgentIds[12] = 3999;
        woundedEventAgentIds[13] = 7776;
        woundedEventAgentIds[14] = 4982;
        woundedEventAgentIds[15] = 6376;
        woundedEventAgentIds[16] = 2002;
        woundedEventAgentIds[17] = 3722;
        woundedEventAgentIds[18] = 7216;
        woundedEventAgentIds[19] = 3132;

        expectEmitCheckAll();
        emit Wounded(1, woundedEventAgentIds);

        expectEmitCheckAll();
        emit RoundStarted(2);

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(infiltration)).rawFulfillRandomWords(_computeVrfRequestId(1), randomWords);

        (bool exists, uint40 roundId, uint256 randomWord) = infiltration.randomnessRequests(_computeVrfRequestId(1));

        assertTrue(exists);
        assertEq(roundId, 1);

        assertEq(randomWord, randomWords[0]);

        (
            uint16 activeAgents,
            uint16 woundedAgents,
            uint16 healingAgents,
            uint16 deadAgents,
            uint16 escapedAgents,
            uint40 currentRoundId,
            uint40 currentRoundBlockNumber,
            uint40 randomnessLastRequestedAt,
            ,
            ,
            uint256 secondaryLooksPrizePool
        ) = infiltration.gameInfo();

        assertEq(activeAgents, MAX_SUPPLY - 20);
        assertEq(woundedAgents, 20);
        assertEq(healingAgents, 0);
        assertEq(deadAgents, 0);
        assertEq(escapedAgents, 0);
        assertEq(currentRoundId, 2);
        assertEq(currentRoundBlockNumber, 18_090_639);
        assertEq(randomnessLastRequestedAt, 0);
        assertEq(secondaryLooksPrizePool, 0);

        (uint256[] memory woundedAgentIds, ) = infiltration.getRoundInfo({roundId: 1});
        assertEq(woundedAgentIds.length, 20);

        for (uint256 i; i < 20; i++) {
            IInfiltration.Agent memory agent = infiltration.getAgent(woundedAgentIds[i]);

            assertEq(agent.agentId, woundedAgentIds[i]);
            assertEq(uint8(agent.status), uint8(IInfiltration.AgentStatus.Wounded));
            assertEq(agent.woundedAt, 1);
            assertEq(agent.healCount, 0);

            assertAgentIsTransferrable(woundedAgentIds[i]);
        }

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_fulfillRandomWords_HealRequestFulfilled() public {
        _startGameAndDrawOneRound();

        (uint256[] memory woundedAgentIds, ) = infiltration.getRoundInfo({roundId: 1});
        assertEq(woundedAgentIds.length, 20);

        _drawXRounds(1);

        _heal({roundId: 3, woundedAgentIds: woundedAgentIds});

        _startNewRound();

        uint256 agentIdThatWasKilled = woundedAgentIds[0];

        IInfiltration.HealResult[] memory healResults = new IInfiltration.HealResult[](20);
        for (uint256 i; i < 20; i++) {
            healResults[i].agentId = woundedAgentIds[i];

            if (woundedAgentIds[i] == agentIdThatWasKilled) {
                healResults[i].outcome = IInfiltration.HealOutcome.Killed;
            } else {
                healResults[i].outcome = IInfiltration.HealOutcome.Healed;
            }
        }

        expectEmitCheckAll();
        emit HealRequestFulfilled(3, healResults);

        expectEmitCheckAll();
        emit RoundStarted(4);

        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = (69 * 10_000_000_000) + 9_900_000_000; // survival rate 99%, first one gets killed

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(infiltration)).rawFulfillRandomWords(_computeVrfRequestId(3), randomWords);

        assertEq(
            looks.balanceOf(0x000000000000000000000000000000000000dEaD),
            (HEAL_BASE_COST * 19) / 4,
            "There should be 19 agents revived with 25% payment burned"
        );

        assertEq(infiltration.agentsAlive(), MAX_SUPPLY - 1);

        // Originally the dead agent, now swapped with the last agent in the mapping
        IInfiltration.Agent memory agent = infiltration.getAgent(MAX_SUPPLY);

        assertEq(agent.agentId, agentIdThatWasKilled);
        assertEq(uint8(agent.status), uint8(IInfiltration.AgentStatus.Dead));
        assertEq(agent.woundedAt, 0);
        assertEq(agent.healCount, 0);

        assertAgentIsNotTransferrable(agentIdThatWasKilled, IInfiltration.AgentStatus.Dead);

        // Originally the last agent, now swapped with the agent ID that was killed
        agent = infiltration.getAgent(agentIdThatWasKilled);

        assertEq(agent.agentId, MAX_SUPPLY);
        assertEq(uint8(agent.status), uint8(IInfiltration.AgentStatus.Active));
        assertEq(agent.woundedAt, 0);
        assertEq(agent.healCount, 0);

        for (uint256 i; i < woundedAgentIds.length; i++) {
            if (woundedAgentIds[i] != agentIdThatWasKilled) {
                _assertHealedAgent(woundedAgentIds[i]);
            }
        }

        (bool exists, uint40 roundId, uint256 randomWord) = infiltration.randomnessRequests(_computeVrfRequestId(3));

        assertTrue(exists);
        assertEq(roundId, 3);
        assertEq(randomWord, randomWords[0]);

        (
            uint16 activeAgents,
            uint16 woundedAgents,
            uint16 healingAgents,
            uint16 deadAgents,
            uint16 escapedAgents,
            uint40 currentRoundId,
            uint40 currentRoundBlockNumber,
            uint40 randomnessLastRequestedAt,
            ,
            ,
            uint256 secondaryLooksPrizePool
        ) = infiltration.gameInfo();

        assertEq(activeAgents, MAX_SUPPLY - 39);
        assertEq(woundedAgents, 38, "There should be 2 rounds of wounded agents - 1 dead agents");
        assertEq(healingAgents, 0);
        assertEq(deadAgents, 1);
        assertEq(escapedAgents, 0);
        assertEq(currentRoundId, 4);
        assertEq(currentRoundBlockNumber, 18_090_739);
        assertEq(randomnessLastRequestedAt, 0);
        assertEq(secondaryLooksPrizePool, 0);

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_fulfillRandomWords_KillWoundedAgents() public {
        _startGameAndDrawOneRound();

        uint256[] memory randomWords = _randomWords();

        for (uint256 roundId = 2; roundId <= ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD + 1; roundId++) {
            _startNewRound();

            // Just so that each round has different random words
            randomWords[0] += roundId;

            if (roundId == ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD + 1) {
                (uint256[] memory woundedAgentIdsFromRound, ) = infiltration.getRoundInfo({
                    roundId: uint40(roundId - ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD)
                });
                assertEq(woundedAgentIdsFromRound.length, 20);
                uint256[] memory woundedAgentIds = new uint256[](woundedAgentIdsFromRound.length);
                for (uint256 i; i < woundedAgentIdsFromRound.length; i++) {
                    woundedAgentIds[i] = woundedAgentIdsFromRound[i];
                }
                expectEmitCheckAll();
                emit Killed(roundId - ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD, woundedAgentIds);
            }

            expectEmitCheckAll();
            emit RoundStarted(roundId + 1);

            uint256 requestId = _computeVrfRequestId(uint64(roundId));
            vm.prank(VRF_COORDINATOR);
            VRFConsumerBaseV2(address(infiltration)).rawFulfillRandomWords(requestId, randomWords);
        }

        (
            uint16 activeAgents,
            uint16 woundedAgents,
            uint16 healingAgents,
            uint16 deadAgents,
            uint16 escapedAgents,
            uint40 currentRoundId,
            uint40 currentRoundBlockNumber,
            uint40 randomnessLastRequestedAt,
            ,
            ,
            uint256 secondaryLooksPrizePool
        ) = infiltration.gameInfo();

        assertEq(activeAgents, 9_090);
        assertEq(woundedAgents, 890);
        assertEq(healingAgents, 0);
        assertEq(deadAgents, 20);
        assertEq(escapedAgents, 0);
        assertEq(currentRoundId, 50);
        assertEq(currentRoundBlockNumber, 18_093_039);
        assertEq(randomnessLastRequestedAt, 0);
        assertEq(secondaryLooksPrizePool, 0);

        (uint256[] memory deadAgentIds, ) = infiltration.getRoundInfo(1);
        for (uint256 i; i < deadAgentIds.length; i++) {
            uint256 index = infiltration.agentIndex(deadAgentIds[i]);
            assertGt(index, MAX_SUPPLY - 20, "Dead agents are not placed in the end of the mapping");

            IInfiltration.Agent memory agent = infiltration.getAgent(index);

            assertEq(agent.agentId, deadAgentIds[i]);
            assertEq(uint8(agent.status), uint8(IInfiltration.AgentStatus.Dead));
            assertEq(agent.woundedAt, 0);
            assertEq(agent.healCount, 0);

            assertAgentIsNotTransferrable(agent.agentId, IInfiltration.AgentStatus.Dead);

            // Swapped agent from the end of the mapping
            agent = infiltration.getAgent(deadAgentIds[i]);

            assertEq(agent.agentId, index);

            if (agent.status == IInfiltration.AgentStatus.Active) {
                assertEq(uint8(agent.status), uint8(IInfiltration.AgentStatus.Active));
                assertEq(agent.woundedAt, 0);
            } else {
                assertEq(uint8(agent.status), uint8(IInfiltration.AgentStatus.Wounded));
                assertNotEq(agent.woundedAt, 0);
            }

            assertEq(agent.healCount, 0);
        }

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_fulfillRandomWords_DownTo50ActiveAgents_WithHealingAgents() public {
        _startGameAndDrawOneRound();
        _drawXRounds(2_220);

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
        assertEq(activeAgents, 51, "Active agents should be greater than 50");
        assertEq(woundedAgents, 48);
        assertEq(healingAgents, 0);
        assertEq(deadAgents, 9_901);
        assertEq(escapedAgents, 0);

        uint256[] memory healingAgentIds = new uint256[](2);
        healingAgentIds[0] = 8_534;
        healingAgentIds[1] = 3_214;

        for (uint256 i; i < healingAgentIds.length; i++) {
            IInfiltration.Agent memory agent = infiltration.getAgent(i + 1);
            assertEq(agent.agentId, healingAgentIds[i]);
            assertEq(uint8(agent.status), uint8(IInfiltration.AgentStatus.Wounded));
            assertEq(agent.healCount, 0);
        }

        _heal({roundId: 2_222, woundedAgentIds: healingAgentIds});

        uint256[] memory escapingAgentIds = new uint256[](1);

        IInfiltration.Agent memory escapingAgentOne = infiltration.getAgent(50);
        assertEq(uint8(escapingAgentOne.status), uint8(IInfiltration.AgentStatus.Active));
        address agentOwnerOne = IERC721A(address(infiltration)).ownerOf(escapingAgentOne.agentId);
        escapingAgentIds[0] = escapingAgentOne.agentId;
        vm.prank(agentOwnerOne);
        infiltration.escape(escapingAgentIds);

        IInfiltration.Agent memory escapingAgentTwo = infiltration.getAgent(51);
        assertEq(uint8(escapingAgentTwo.status), uint8(IInfiltration.AgentStatus.Active));
        address agentOwnerTwo = IERC721A(address(infiltration)).ownerOf(escapingAgentTwo.agentId);
        escapingAgentIds[0] = escapingAgentTwo.agentId;
        vm.prank(agentOwnerTwo);
        infiltration.escape(escapingAgentIds);

        (activeAgents, woundedAgents, healingAgents, deadAgents, escapedAgents, , , , , , ) = infiltration.gameInfo();
        assertEq(activeAgents, 49);
        assertEq(woundedAgents, 46);
        assertEq(healingAgents, 2);
        assertEq(deadAgents, 9_901);
        assertEq(escapedAgents, 2);

        {
            _startNewRound();

            (activeAgents, woundedAgents, healingAgents, deadAgents, escapedAgents, , , , , , ) = infiltration
                .gameInfo();
            assertEq(activeAgents, 49);
            assertEq(woundedAgents, 0);
            assertEq(healingAgents, 2);
            assertEq(deadAgents, 9_947);
            assertEq(escapedAgents, 2);

            uint40 roundId = 2_222;
            uint256 requestId = _computeVrfRequestId(roundId);
            uint256[] memory randomWords = _randomWords();
            randomWords[0] += 7;
            vm.prank(VRF_COORDINATOR);
            VRFConsumerBaseV2(address(infiltration)).rawFulfillRandomWords(requestId, randomWords);
        }

        (activeAgents, woundedAgents, healingAgents, deadAgents, escapedAgents, , , , , , ) = infiltration.gameInfo();
        assertEq(activeAgents, 49);
        assertEq(woundedAgents, 0);
        assertEq(healingAgents, 0);
        assertEq(deadAgents, 9_949);
        assertEq(escapedAgents, 2);

        IInfiltration.Agent memory agent51 = infiltration.getAgent(51);
        assertEq(agent51.agentId, healingAgentIds[1]);

        IInfiltration.Agent memory agent1 = infiltration.getAgent(1);
        assertEq(agent1.agentId, healingAgentIds[0]);
    }

    function test_fulfillRandomWords_DownTo50ActiveAgents_WithHealingAgents_BackTo51ActiveAgentsAfterHealing() public {
        _startGameAndDrawOneRound();
        _drawXRounds(2_220);

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
        assertEq(activeAgents, 51, "Active agents should be greater than 50");
        assertEq(woundedAgents, 48);
        assertEq(healingAgents, 0);
        assertEq(deadAgents, 9_901);
        assertEq(escapedAgents, 0);

        uint256[] memory healingAgentIds = new uint256[](3);
        healingAgentIds[0] = 8_534;
        healingAgentIds[1] = 3_214;
        healingAgentIds[2] = 6_189;

        for (uint256 i; i < healingAgentIds.length; i++) {
            IInfiltration.Agent memory agent = infiltration.getAgent(i + 1);
            assertEq(agent.agentId, healingAgentIds[i]);
            assertEq(uint8(agent.status), uint8(IInfiltration.AgentStatus.Wounded));
            assertEq(agent.healCount, 0);
        }

        _heal({roundId: 2_222, woundedAgentIds: healingAgentIds});

        uint256[] memory escapingAgentIds = new uint256[](1);

        IInfiltration.Agent memory escapingAgentOne = infiltration.getAgent(50);
        assertEq(uint8(escapingAgentOne.status), uint8(IInfiltration.AgentStatus.Active));
        address agentOwnerOne = IERC721A(address(infiltration)).ownerOf(escapingAgentOne.agentId);
        escapingAgentIds[0] = escapingAgentOne.agentId;
        vm.prank(agentOwnerOne);
        infiltration.escape(escapingAgentIds);

        IInfiltration.Agent memory escapingAgentTwo = infiltration.getAgent(51);
        assertEq(uint8(escapingAgentTwo.status), uint8(IInfiltration.AgentStatus.Active));
        address agentOwnerTwo = IERC721A(address(infiltration)).ownerOf(escapingAgentTwo.agentId);
        escapingAgentIds[0] = escapingAgentTwo.agentId;
        vm.prank(agentOwnerTwo);
        infiltration.escape(escapingAgentIds);

        (activeAgents, woundedAgents, healingAgents, deadAgents, escapedAgents, , , , , , ) = infiltration.gameInfo();
        assertEq(activeAgents, 49);
        assertEq(woundedAgents, 45);
        assertEq(healingAgents, 3);
        assertEq(deadAgents, 9_901);
        assertEq(escapedAgents, 2);

        {
            _startNewRound();

            (activeAgents, woundedAgents, healingAgents, deadAgents, escapedAgents, , , , , , ) = infiltration
                .gameInfo();
            assertEq(activeAgents, 49);
            assertEq(woundedAgents, 0);
            assertEq(healingAgents, 3);
            assertEq(deadAgents, 9_946);
            assertEq(escapedAgents, 2);

            uint40 roundId = 2_222;
            uint256 requestId = _computeVrfRequestId(roundId);
            uint256[] memory randomWords = _randomWords();
            randomWords[0] += 7;
            vm.prank(VRF_COORDINATOR);
            VRFConsumerBaseV2(address(infiltration)).rawFulfillRandomWords(requestId, randomWords);
        }

        (activeAgents, woundedAgents, healingAgents, deadAgents, escapedAgents, , , , , , ) = infiltration.gameInfo();
        assertEq(activeAgents, 50);
        assertEq(woundedAgents, 1);
        assertEq(healingAgents, 0);
        assertEq(deadAgents, 9_947);
        assertEq(escapedAgents, 2);

        IInfiltration.Agent memory agent3 = infiltration.getAgent(3);
        assertEq(agent3.agentId, healingAgentIds[2]);

        IInfiltration.Agent memory agent52 = infiltration.getAgent(52);
        assertEq(agent52.agentId, healingAgentIds[1]);

        IInfiltration.Agent memory agent1 = infiltration.getAgent(1);
        assertEq(agent1.agentId, healingAgentIds[0]);
    }

    function test_fulfillRandomWords_DownTo50ActiveAgents_Instakill() public {
        _downTo50ActiveAgents();

        uint256 roundId = 2_223;
        uint256[] memory randomWords = _randomWords();
        randomWords[0] += roundId;

        _startNewRound();

        uint256[] memory killedAgentId = new uint256[](1);
        killedAgentId[0] = 5_256;

        expectEmitCheckAll();
        emit Killed(roundId, killedAgentId);

        expectEmitCheckAll();
        emit RoundStarted(roundId + 1);

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(infiltration)).rawFulfillRandomWords(
            _computeVrfRequestId(uint64(roundId)),
            randomWords
        );

        (
            uint16 activeAgents,
            uint16 woundedAgents,
            uint16 healingAgents,
            uint16 deadAgents,
            uint16 escapedAgents,
            uint40 currentRoundId,
            uint40 currentRoundBlockNumber,
            uint40 randomnessLastRequestedAt,
            ,
            ,
            uint256 secondaryLooksPrizePool
        ) = infiltration.gameInfo();

        assertEq(activeAgents, 49);
        assertEq(woundedAgents, 0);
        assertEq(healingAgents, 0);
        assertEq(deadAgents, 9_951);
        assertEq(escapedAgents, 0);
        assertEq(currentRoundId, roundId + 1);
        assertEq(currentRoundBlockNumber, 18_201_739);
        assertEq(randomnessLastRequestedAt, 0);
        assertEq(secondaryLooksPrizePool, 0);

        for (uint256 i = 1; i <= 49; i++) {
            IInfiltration.Agent memory agent = infiltration.getAgent(i);
            assertEq(uint8(agent.status), uint8(IInfiltration.AgentStatus.Active));
        }

        for (uint256 i = 50; i <= MAX_SUPPLY; i++) {
            IInfiltration.Agent memory agent = infiltration.getAgent(i);
            assertEq(uint8(agent.status), uint8(IInfiltration.AgentStatus.Dead));
            assertAgentIsNotTransferrable(agent.agentId, IInfiltration.AgentStatus.Dead);
        }

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_fulfillRandomWords_DownTo1ActiveAgent() public {
        _downTo50ActiveAgents();
        _downToXActiveAgent(2);

        uint256[] memory randomWords = _randomWords();

        _startNewRound();

        uint256 requestId = _computeVrfRequestId(uint64(_getCurrentRoundId()));

        expectEmitCheckAll();
        emit Won(2_271, 2_941);

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(infiltration)).rawFulfillRandomWords(requestId, randomWords);

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_fulfillRandomWords_InvalidRandomnessFulfillment() public {
        uint256[] memory randomWords = _randomWords();

        _mintOut();

        vm.prank(owner);
        infiltration.startGame();

        expectEmitCheckAll();
        emit InvalidRandomnessFulfillment(_computeVrfRequestId(3), 0, 1);

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(infiltration)).rawFulfillRandomWords(_computeVrfRequestId(3), randomWords);

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function _assertHealedAgent(uint256 healedAgentId) private {
        IInfiltration.Agent memory agent = infiltration.getAgent(healedAgentId);

        assertEq(agent.agentId, healedAgentId);
        assertEq(uint8(agent.status), uint8(IInfiltration.AgentStatus.Active));
        assertEq(agent.woundedAt, 0);
        assertEq(agent.healCount, 1);
    }
}
