// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import {IInfiltration} from "../../contracts/interfaces/IInfiltration.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract Infiltration_ClaimSecondaryPrizes_Test is TestHelpers {
    function setUp() public {
        _forkMainnet();
        _deployInfiltration();
        _setMintPeriod();
    }

    function _stubSecondaryPrizePool(uint256 amount) private {
        uint256 gameInfoSlot = 19;
        uint256 secondaryPrizesSlot = gameInfoSlot + 2;
        vm.deal(address(infiltration), address(infiltration).balance + amount);
        vm.store(address(infiltration), bytes32(secondaryPrizesSlot), bytes32(amount));

        (, , , , , , , , , uint256 secondaryPrizePool, ) = infiltration.gameInfo();
        assertEq(secondaryPrizePool, amount);
    }

    function _topFiftySecondaryPrizeAmounts() private pure returns (uint256[50] memory secondaryPrizeAmounts) {
        secondaryPrizeAmounts = [
            uint256(2636000000000000000),
            uint256(1297000000000000000),
            uint256(851000000000000000),
            uint256(628000000000000000),
            uint256(494000000000000000),
            uint256(405000000000000000),
            uint256(342000000000000000),
            uint256(294000000000000000),
            uint256(257000000000000000),
            uint256(227000000000000000),
            uint256(202000000000000000),
            uint256(182000000000000000),
            uint256(165000000000000000),
            uint256(150000000000000000),
            uint256(138000000000000000),
            uint256(126000000000000000),
            uint256(117000000000000000),
            uint256(108000000000000000),
            uint256(100000000000000000),
            uint256(93000000000000000),
            uint256(87000000000000000),
            uint256(81000000000000000),
            uint256(76000000000000000),
            uint256(71000000000000000),
            uint256(66000000000000000),
            uint256(62000000000000000),
            uint256(58000000000000000),
            uint256(55000000000000000),
            uint256(51000000000000000),
            uint256(48000000000000000),
            uint256(45000000000000000),
            uint256(43000000000000000),
            uint256(40000000000000000),
            uint256(38000000000000000),
            uint256(36000000000000000),
            uint256(34000000000000000),
            uint256(31000000000000000),
            uint256(30000000000000000),
            uint256(28000000000000000),
            uint256(26000000000000000),
            uint256(24000000000000000),
            uint256(23000000000000000),
            uint256(21000000000000000),
            uint256(20000000000000000),
            uint256(19000000000000000),
            uint256(17000000000000000),
            uint256(16000000000000000),
            uint256(15000000000000000),
            uint256(14000000000000000),
            uint256(13000000000000000)
        ];
    }

    function _topFiftySecondaryLooksPrizeAmounts() private pure returns (uint256[50] memory secondaryPrizeAmounts) {
        secondaryPrizeAmounts = [
            uint256(197700000000000000000),
            uint256(97275000000000000000),
            uint256(63825000000000000000),
            uint256(47100000000000000000),
            uint256(37050000000000000000),
            uint256(30375000000000000000),
            uint256(25650000000000000000),
            uint256(22050000000000000000),
            uint256(19275000000000000000),
            uint256(17025000000000000000),
            uint256(15150000000000000000),
            uint256(13650000000000000000),
            uint256(12375000000000000000),
            uint256(11250000000000000000),
            uint256(10350000000000000000),
            uint256(9450000000000000000),
            uint256(8775000000000000000),
            uint256(8100000000000000000),
            uint256(7500000000000000000),
            uint256(6975000000000000000),
            uint256(6525000000000000000),
            uint256(6075000000000000000),
            uint256(5700000000000000000),
            uint256(5325000000000000000),
            uint256(4950000000000000000),
            uint256(4650000000000000000),
            uint256(4350000000000000000),
            uint256(4125000000000000000),
            uint256(3825000000000000000),
            uint256(3600000000000000000),
            uint256(3375000000000000000),
            uint256(3225000000000000000),
            uint256(3000000000000000000),
            uint256(2850000000000000000),
            uint256(2700000000000000000),
            uint256(2550000000000000000),
            uint256(2325000000000000000),
            uint256(2250000000000000000),
            uint256(2100000000000000000),
            uint256(1950000000000000000),
            uint256(1800000000000000000),
            uint256(1725000000000000000),
            uint256(1575000000000000000),
            uint256(1500000000000000000),
            uint256(1425000000000000000),
            uint256(1275000000000000000),
            uint256(1200000000000000000),
            uint256(1125000000000000000),
            uint256(1050000000000000000),
            uint256(975000000000000000)
        ];
    }

    function test_claimSecondaryPrizes() public {
        _downTo1ActiveAgent();
        _stubSecondaryPrizePool(10 ether);

        uint256[50] memory secondaryPrizeAmounts = _topFiftySecondaryPrizeAmounts();

        for (uint256 i = 1; i <= 50; i++) {
            IInfiltration.Agent memory agent = infiltration.getAgent(i);
            address winner = _ownerOf(agent.agentId);
            vm.deal(winner, 0);
            uint256 expectedAmount = secondaryPrizeAmounts[i - 1];

            expectEmitCheckAll();
            emit PrizeClaimed(agent.agentId, address(0), expectedAmount);

            vm.prank(winner);
            infiltration.claimSecondaryPrizes(agent.agentId);

            assertEq(winner.balance, expectedAmount);
        }
        assertEq(address(infiltration).balance, 425 ether);

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_claimSecondaryLooksPrizes() public {
        _startGameAndDrawOneRound();

        uint256[50] memory secondaryPrizeAmounts = _topFiftySecondaryLooksPrizeAmounts();

        (uint256[] memory woundedAgentIds, ) = infiltration.getRoundInfo({roundId: 1});
        assertEq(woundedAgentIds.length, 20);

        _drawXRounds(1);

        _heal({roundId: 3, woundedAgentIds: woundedAgentIds});

        _startNewRound();

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(infiltration)).rawFulfillRandomWords(_computeVrfRequestId(3), _randomWords());

        _drawXRounds(2_220);
        _downToXActiveAgent(1);

        uint256 expectedPoolAmount = 750 ether;
        assertEq(looks.balanceOf(address(infiltration)), expectedPoolAmount);
        (, , , , , , , , , , uint256 secondaryLooksPrizePool) = infiltration.gameInfo();
        assertEq(secondaryLooksPrizePool, 0, "Secondary LOOKS prize pool is only set on the first claim");

        for (uint256 i = 1; i <= 50; i++) {
            IInfiltration.Agent memory agent = infiltration.getAgent(i);
            address winner = _ownerOf(agent.agentId);
            deal(address(looks), winner, 0);

            uint256 expectedAmount = secondaryPrizeAmounts[i - 1];

            expectEmitCheckAll();
            emit PrizeClaimed(agent.agentId, address(looks), expectedAmount);

            vm.prank(winner);
            infiltration.claimSecondaryPrizes(agent.agentId);

            assertEq(looks.balanceOf(winner), expectedAmount);
        }

        assertEq(looks.balanceOf(address(infiltration)), 0);
        (, , , , , , , , , , secondaryLooksPrizePool) = infiltration.gameInfo();
        assertEq(secondaryLooksPrizePool, expectedPoolAmount, "Secondary LOOKS prize pool should now be set");

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_claimSecondaryPrizes_RevertIf_InvalidPlacement() public {
        _downTo1ActiveAgent();
        _stubSecondaryPrizePool(10 ether);

        for (uint256 i = 51; i <= MAX_SUPPLY; i++) {
            IInfiltration.Agent memory agent = infiltration.getAgent(i);
            address agentOwner = _ownerOf(agent.agentId);
            vm.prank(agentOwner);
            vm.expectRevert(IInfiltration.InvalidPlacement.selector);
            infiltration.claimSecondaryPrizes(agent.agentId);
        }

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_claimSecondaryPrizes_RevertIf_NothingToClaim() public {
        _downTo1ActiveAgent();
        _stubSecondaryPrizePool(10 ether);

        for (uint256 i = 1; i <= 50; i++) {
            IInfiltration.Agent memory agent = infiltration.getAgent(i);
            address winner = _ownerOf(agent.agentId);

            vm.startPrank(winner);

            infiltration.claimSecondaryPrizes(agent.agentId);

            vm.expectRevert(IInfiltration.NothingToClaim.selector);
            infiltration.claimSecondaryPrizes(agent.agentId);

            vm.stopPrank();
        }

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_claimSecondaryPrizes_RevertIf_GameIsStillRunning() public {
        _downTo50ActiveAgents();
        _downToXActiveAgent(2);

        _stubSecondaryPrizePool(10 ether);

        for (uint256 i = 1; i <= 50; i++) {
            IInfiltration.Agent memory agent = infiltration.getAgent(i);
            address winner = _ownerOf(agent.agentId);

            vm.prank(winner);
            vm.expectRevert(IInfiltration.GameIsStillRunning.selector);
            infiltration.claimSecondaryPrizes(agent.agentId);
        }

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_claimSecondaryPrizes_RevertIf_NotAgentOwner() public {
        _downTo1ActiveAgent();
        _stubSecondaryPrizePool(10 ether);

        for (uint256 i = 1; i <= 50; i++) {
            IInfiltration.Agent memory agent = infiltration.getAgent(i);
            vm.expectRevert(IInfiltration.NotAgentOwner.selector);
            infiltration.claimSecondaryPrizes(agent.agentId);
        }

        invariant_totalAgentsIsEqualToTotalSupply();
    }
}
