// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITransferManager} from "@looksrare/contracts-transfer-manager/contracts/interfaces/ITransferManager.sol";
import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import {Infiltration} from "../../contracts/Infiltration.sol";
import {IInfiltration} from "../../contracts/interfaces/IInfiltration.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract Infiltration_StartNewRound_Test is TestHelpers {
    function setUp() public {
        _forkMainnet();
        _deployInfiltration();
        _setMintPeriod();
    }

    function test_startNewRound() public {
        _startGameAndDrawOneRound();

        blockNumber += BLOCKS_PER_ROUND;
        vm.roll(blockNumber);

        expectEmitCheckAll();
        emit RandomnessRequested(2, _computeVrfRequestId(2));

        infiltration.startNewRound();

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_startNewRound_LessThan50ActiveAgentsLeft() public {
        _startGameAndDrawOneRound();

        _drawXRounds(2_221);

        (uint16 activeAgents, uint16 woundedAgents, , uint16 deadAgents, , , , , , , ) = infiltration.gameInfo();
        assertEq(activeAgents, 50);
        assertEq(woundedAgents, 48);
        assertEq(deadAgents, 9_902);

        uint256[] memory killedAgentIds = new uint256[](woundedAgents);
        killedAgentIds[0] = 135;
        killedAgentIds[1] = 5371;
        killedAgentIds[2] = 4732;
        killedAgentIds[3] = 226;
        killedAgentIds[4] = 6196;
        killedAgentIds[5] = 1223;
        killedAgentIds[6] = 3214;
        killedAgentIds[7] = 1362;
        killedAgentIds[8] = 155;
        killedAgentIds[9] = 8371;
        killedAgentIds[10] = 6049;
        killedAgentIds[11] = 4476;
        killedAgentIds[12] = 1116;
        killedAgentIds[13] = 1459;
        killedAgentIds[14] = 5607;
        killedAgentIds[15] = 3880;
        killedAgentIds[16] = 7872;
        killedAgentIds[17] = 3728;
        killedAgentIds[18] = 1245;
        killedAgentIds[19] = 4518;
        killedAgentIds[20] = 125;
        killedAgentIds[21] = 4356;
        killedAgentIds[22] = 9596;
        killedAgentIds[23] = 4478;
        killedAgentIds[24] = 853;
        killedAgentIds[25] = 7471;
        killedAgentIds[26] = 8534;
        killedAgentIds[27] = 548;
        killedAgentIds[28] = 6268;
        killedAgentIds[29] = 7379;
        killedAgentIds[30] = 1659;
        killedAgentIds[31] = 8595;
        killedAgentIds[32] = 303;
        killedAgentIds[33] = 6189;
        killedAgentIds[34] = 1978;
        killedAgentIds[35] = 6369;
        killedAgentIds[36] = 6812;
        killedAgentIds[37] = 2053;
        killedAgentIds[38] = 6590;
        killedAgentIds[39] = 3627;
        killedAgentIds[40] = 4928;
        killedAgentIds[41] = 6148;
        killedAgentIds[42] = 2718;
        killedAgentIds[43] = 1796;
        killedAgentIds[44] = 7676;
        killedAgentIds[45] = 1522;
        killedAgentIds[46] = 1358;
        killedAgentIds[47] = 3845;

        for (uint256 roundId = 2_175; roundId < 2_223; roundId++) {
            uint256[] memory killedAgentIdInRound = new uint256[](1);
            killedAgentIdInRound[0] = killedAgentIds[roundId - 2_175];

            expectEmitCheckAll();
            emit Killed(roundId, killedAgentIdInRound);
        }

        _startNewRound();

        (activeAgents, woundedAgents, , deadAgents, , , , , , , ) = infiltration.gameInfo();
        assertEq(activeAgents, 50);
        assertEq(woundedAgents, 0);
        assertEq(deadAgents, 9_950);

        for (uint256 i = 1; i <= 50; i++) {
            IInfiltration.Agent memory agent = infiltration.getAgent(i);
            assertEq(uint8(agent.status), uint8(IInfiltration.AgentStatus.Active));
        }

        for (uint256 i = 51; i <= MAX_SUPPLY; i++) {
            IInfiltration.Agent memory agent = infiltration.getAgent(i);
            assertNotEq(uint8(agent.status), uint8(IInfiltration.AgentStatus.Active));
        }

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_startNewRound_LessThan50ActiveAgentsLeft_KillFromRoundOne() public {
        IInfiltration.ConstructorCalldata memory constructorCalldata = _constructorCalldata();
        constructorCalldata.maxSupply = 98;
        constructorCalldata.agentsToWoundPerRoundInBasisPoints = 200;
        constructorCalldata.maxMintPerAddress = 2;
        infiltration = new Infiltration(constructorCalldata);

        vm.prank(SUBSCRIPTION_ADMIN);
        VRFCoordinatorV2Interface(VRF_COORDINATOR).addConsumer(SUBSCRIPTION_ID, address(infiltration));

        vm.prank(SUBSCRIPTION_ADMIN);
        ITransferManager(TRANSFER_MANAGER).allowOperator(address(infiltration));

        _setMintPeriod();

        vm.warp(_mintStart());

        uint160 startingUser = 11;

        for (
            uint160 i = startingUser;
            i < (constructorCalldata.maxSupply / constructorCalldata.maxMintPerAddress + startingUser);
            i++
        ) {
            vm.deal(address(i), PRICE * constructorCalldata.maxMintPerAddress);
            vm.prank(address(i));
            infiltration.mint{value: PRICE * constructorCalldata.maxMintPerAddress}({
                quantity: constructorCalldata.maxMintPerAddress
            });
        }

        vm.prank(owner);
        infiltration.startGame();

        uint256[] memory randomWords = _randomWords();
        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(infiltration)).rawFulfillRandomWords(_computeVrfRequestId(1), randomWords);

        _drawXRounds(47);

        uint256[] memory killedAgentIds = new uint256[](48);
        killedAgentIds[0] = 37;
        killedAgentIds[1] = 38;
        killedAgentIds[2] = 39;
        killedAgentIds[3] = 40;
        killedAgentIds[4] = 43;
        killedAgentIds[5] = 47;
        killedAgentIds[6] = 52;
        killedAgentIds[7] = 58;
        killedAgentIds[8] = 65;
        killedAgentIds[9] = 73;
        killedAgentIds[10] = 82;
        killedAgentIds[11] = 92;
        killedAgentIds[12] = 5;
        killedAgentIds[13] = 17;
        killedAgentIds[14] = 30;
        killedAgentIds[15] = 44;
        killedAgentIds[16] = 59;
        killedAgentIds[17] = 75;
        killedAgentIds[18] = 93;
        killedAgentIds[19] = 12;
        killedAgentIds[20] = 31;
        killedAgentIds[21] = 51;
        killedAgentIds[22] = 72;
        killedAgentIds[23] = 94;
        killedAgentIds[24] = 19;
        killedAgentIds[25] = 45;
        killedAgentIds[26] = 68;
        killedAgentIds[27] = 95;
        killedAgentIds[28] = 23;
        killedAgentIds[29] = 53;
        killedAgentIds[30] = 80;
        killedAgentIds[31] = 13;
        killedAgentIds[32] = 46;
        killedAgentIds[33] = 76;
        killedAgentIds[34] = 10;
        killedAgentIds[35] = 48;
        killedAgentIds[36] = 79;
        killedAgentIds[37] = 18;
        killedAgentIds[38] = 54;
        killedAgentIds[39] = 96;
        killedAgentIds[40] = 33;
        killedAgentIds[41] = 74;
        killedAgentIds[42] = 16;
        killedAgentIds[43] = 60;
        killedAgentIds[44] = 3;
        killedAgentIds[45] = 49;
        killedAgentIds[46] = 97;
        killedAgentIds[47] = 41;

        for (uint256 roundId = 1; roundId < 48; roundId++) {
            uint256[] memory killedAgentIdInRound = new uint256[](1);
            killedAgentIdInRound[0] = killedAgentIds[roundId - 1];

            expectEmitCheckAll();
            emit Killed(roundId, killedAgentIdInRound);
        }

        expectEmitCheckAll();
        emit RandomnessRequested(49, _computeVrfRequestId(49));

        _startNewRound();

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
        assertEq(activeAgents, 50);
        assertEq(healingAgents, 0);
        assertEq(woundedAgents, 0);
        assertEq(deadAgents, 48);
        assertEq(escapedAgents, 0);

        assertEq(infiltration.totalSupply(), 98);

        for (uint256 i = 1; i <= 50; i++) {
            IInfiltration.Agent memory agent = infiltration.getAgent(i);
            assertEq(uint8(agent.status), uint8(IInfiltration.AgentStatus.Active));
        }

        for (uint256 i = 51; i <= constructorCalldata.maxSupply; i++) {
            IInfiltration.Agent memory agent = infiltration.getAgent(i);
            assertNotEq(uint8(agent.status), uint8(IInfiltration.AgentStatus.Active));
        }
    }

    function test_startNewRound_RetryRandomnessRequestFromStartGame() public {
        uint256[] memory randomWords = _randomWords();

        _mintOut();

        vm.prank(owner);
        infiltration.startGame();

        vm.warp(_mintStart() - 1 seconds);

        vm.expectRevert(IInfiltration.TooEarlyToRetryRandomnessRequest.selector);
        infiltration.startNewRound();

        // We can retry after 1 day
        vm.warp(block.timestamp + 1 seconds);

        infiltration.startNewRound();

        expectEmitCheckAll();
        emit RoundStarted(2);

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(infiltration)).rawFulfillRandomWords(
            91803218063569953576421322284787450412809818979767505862058471524642265717640,
            randomWords
        );

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_startNewRound_RevertIf_TooEarlyToRetryRandomnessRequest() public {
        uint256[] memory randomWords = _randomWords();

        _mintOut();

        vm.prank(owner);
        infiltration.startGame();

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(infiltration)).rawFulfillRandomWords(_computeVrfRequestId(1), randomWords);

        _startNewRound();

        vm.warp(_mintStart() - 1 seconds);

        vm.expectRevert(IInfiltration.TooEarlyToRetryRandomnessRequest.selector);
        infiltration.startNewRound();

        // We can retry after 1 day
        vm.warp(block.timestamp + 1 seconds);

        infiltration.startNewRound();

        expectEmitCheckAll();
        emit RoundStarted(3);

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(infiltration)).rawFulfillRandomWords(
            106004099115117355345019119921640962941615220554039446830215227284997429630061,
            randomWords
        );

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_startNewRound_RevertIf_RandomnessRequestAlreadyExists() public {
        uint256[] memory randomWords = _randomWords();

        _mintOut();

        vm.prank(owner);
        infiltration.startGame();

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(infiltration)).rawFulfillRandomWords(_computeVrfRequestId(1), randomWords);

        _stubRandomnessRequestExistence(_computeVrfRequestId(2), true);

        vm.expectRevert(IInfiltration.RandomnessRequestAlreadyExists.selector);
        _startNewRound();

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_startNewRound_RevertIf_GameOver() public {
        _downTo1ActiveAgent();

        blockNumber += BLOCKS_PER_ROUND;
        vm.roll(blockNumber);

        vm.expectRevert(IInfiltration.GameOver.selector);
        _startNewRound();

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_startNewRound_RevertIf_GameNotYetBegun() public {
        _mintOut();

        vm.expectRevert(IInfiltration.GameNotYetBegun.selector);
        infiltration.startNewRound();
    }

    function test_startNewRound_RevertIf_TooEarlyToStartNewRound() public {
        _startGameAndDrawOneRound();

        blockNumber += (BLOCKS_PER_ROUND - 1);
        vm.roll(blockNumber);

        vm.expectRevert(IInfiltration.TooEarlyToStartNewRound.selector);
        infiltration.startNewRound();

        invariant_totalAgentsIsEqualToTotalSupply();
    }
}
