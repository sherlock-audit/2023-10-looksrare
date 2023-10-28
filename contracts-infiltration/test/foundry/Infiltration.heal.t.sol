// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";
import {ITransferManager} from "@looksrare/contracts-transfer-manager/contracts/interfaces/ITransferManager.sol";
import {IERC721A} from "erc721a/contracts/IERC721A.sol";

import {IInfiltration} from "../../contracts/interfaces/IInfiltration.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract Infiltration_Heal_Test is TestHelpers {
    function setUp() public {
        _forkMainnet();
        _deployInfiltration();
        _setMintPeriod();
    }

    function test_heal() public {
        _startGameAndDrawOneRound();

        _drawXRounds(1);

        (uint256[] memory woundedAgentIds, ) = infiltration.getRoundInfo({roundId: 1});

        assertEq(infiltration.costToHeal(woundedAgentIds), HEAL_BASE_COST * woundedAgentIds.length);

        _heal({roundId: 3, woundedAgentIds: woundedAgentIds});

        assertAgentIdsAreHealing(woundedAgentIds);

        (, uint256[] memory healingAgentIds) = infiltration.getRoundInfo({roundId: 1});
        assertAgentIdsAreHealing(healingAgentIds);

        (, uint16 woundedAgents, uint16 healingAgents, , , , , , , , ) = infiltration.gameInfo();
        assertEq(woundedAgents, 19);
        assertEq(healingAgents, woundedAgentIds.length);

        vm.expectRevert(
            abi.encodePacked(
                IInfiltration.InvalidAgentStatus.selector,
                abi.encode(woundedAgentIds[0], IInfiltration.AgentStatus.Wounded)
            )
        );
        infiltration.costToHeal(woundedAgentIds);

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_heal_Multiple() public {
        _startGameAndDrawOneRound();

        _drawXRounds(1);

        (uint256[] memory woundedAgentIds, ) = infiltration.getRoundInfo({roundId: 1});

        uint256[] memory costs = new uint256[](woundedAgentIds.length);
        for (uint256 i; i < woundedAgentIds.length; i++) {
            costs[i] = HEAL_BASE_COST;
        }

        uint256 totalCost = HEAL_BASE_COST * woundedAgentIds.length;

        assertEq(infiltration.costToHeal(woundedAgentIds), totalCost);

        for (uint256 i; i < woundedAgentIds.length; i++) {
            address owner = infiltration.ownerOf(woundedAgentIds[i]);
            vm.prank(owner);
            IERC721A(address(infiltration)).transferFrom(owner, user1, woundedAgentIds[i]);
        }

        looks.mint(user1, totalCost);

        vm.startPrank(user1);
        _grantLooksApprovals();
        looks.approve(TRANSFER_MANAGER, totalCost);

        expectEmitCheckAll();
        emit HealRequestSubmitted(3, woundedAgentIds, costs);

        infiltration.heal(woundedAgentIds);
        vm.stopPrank();

        assertAgentIdsAreHealing(woundedAgentIds);

        (, uint256[] memory healingAgentIds) = infiltration.getRoundInfo({roundId: 3});
        assertAgentIdsAreHealing(healingAgentIds);

        (, uint16 woundedAgents, uint16 healingAgents, , , , , , , , ) = infiltration.gameInfo();
        assertEq(woundedAgents, 19);
        assertEq(healingAgents, woundedAgentIds.length);

        vm.expectRevert(
            abi.encodePacked(
                IInfiltration.InvalidAgentStatus.selector,
                abi.encode(woundedAgentIds[0], IInfiltration.AgentStatus.Wounded)
            )
        );
        infiltration.costToHeal(woundedAgentIds);

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_heal_RevertIf_AgentIdBeyondTotalSupply() public {
        _startGameAndDrawOneRound();

        uint256 agentId = infiltration.totalSupply() + 1;
        uint256[] memory healingAgentIds = new uint256[](1);
        healingAgentIds[0] = agentId;

        looks.mint(user1, HEAL_BASE_COST);

        vm.startPrank(user1);
        _grantLooksApprovals();
        looks.approve(TRANSFER_MANAGER, HEAL_BASE_COST);

        vm.expectRevert(
            abi.encodePacked(
                IInfiltration.InvalidAgentStatus.selector,
                abi.encode(agentId, IInfiltration.AgentStatus.Wounded)
            )
        );
        infiltration.heal(healingAgentIds);

        agentId = uint256(type(uint16).max) + 1;
        healingAgentIds[0] = agentId;

        vm.expectRevert(
            abi.encodePacked(
                IInfiltration.InvalidAgentStatus.selector,
                abi.encode(agentId, IInfiltration.AgentStatus.Wounded)
            )
        );
        infiltration.heal(healingAgentIds);

        vm.stopPrank();
    }

    function test_heal_RevertIf_DuplicatedAgentIds() public {
        _startGameAndDrawOneRound();

        _drawXRounds(1);

        (uint256[] memory woundedAgentIds, ) = infiltration.getRoundInfo({roundId: 1});

        uint256 agentId = woundedAgentIds[0];
        uint256[] memory healingAgentIds = new uint256[](2);
        healingAgentIds[0] = agentId;
        healingAgentIds[1] = agentId;

        address agentOwner = _ownerOf(agentId);

        uint256 cost = HEAL_BASE_COST + HEAL_BASE_COST * 2;
        looks.mint(agentOwner, cost);

        vm.startPrank(agentOwner);
        _grantLooksApprovals();
        looks.approve(TRANSFER_MANAGER, cost);

        vm.expectRevert(
            abi.encodePacked(
                IInfiltration.InvalidAgentStatus.selector,
                abi.encode(agentId, IInfiltration.AgentStatus.Wounded)
            )
        );
        infiltration.heal(healingAgentIds);
        vm.stopPrank();

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_heal_RevertIf_HealingDisabled() public {
        _downTo50ActiveAgents();

        (uint256[] memory woundedAgentIds, ) = infiltration.getRoundInfo({roundId: 2_172});

        uint256 agentId = woundedAgentIds[0];
        address agentOwner = infiltration.ownerOf(agentId);

        looks.mint(agentOwner, HEAL_BASE_COST);

        vm.startPrank(agentOwner);

        _grantLooksApprovals();
        looks.approve(TRANSFER_MANAGER, HEAL_BASE_COST);

        vm.expectRevert(IInfiltration.HealingDisabled.selector);
        infiltration.heal(woundedAgentIds);

        vm.stopPrank();

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_heal_RevertIf_NoAgentsProvided() public {
        _startGameAndDrawOneRound();
        vm.expectRevert(IInfiltration.NoAgentsProvided.selector);
        infiltration.heal(new uint256[](0));

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_heal_RevertIf_InvalidAgentStatus() public {
        _startGameAndDrawOneRound();

        _drawXRounds(1);

        (uint256[] memory woundedAgentIds, ) = infiltration.getRoundInfo({roundId: 1});

        uint256 agentId = woundedAgentIds[0];
        address agentOwner = infiltration.ownerOf(agentId);

        looks.mint(agentOwner, HEAL_BASE_COST);

        vm.startPrank(agentOwner);

        _grantLooksApprovals();
        looks.approve(TRANSFER_MANAGER, HEAL_BASE_COST);

        uint256[] memory agentIds = new uint256[](1);
        agentIds[0] = agentId;

        infiltration.heal(agentIds);

        vm.expectRevert(
            abi.encodePacked(
                IInfiltration.InvalidAgentStatus.selector,
                abi.encode(agentId, IInfiltration.AgentStatus.Wounded)
            )
        );
        infiltration.heal(agentIds);

        vm.stopPrank();

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_heal_RevertIf_HealDeadlinePassed() public {
        _startGameAndDrawOneRound();

        _drawXRounds(ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD + 1);

        (uint256[] memory woundedAgentIds, ) = infiltration.getRoundInfo({roundId: 1});

        uint256 agentId = woundedAgentIds[0];
        address agentOwner = infiltration.ownerOf(agentId);

        looks.mint(agentOwner, HEAL_BASE_COST);

        vm.startPrank(agentOwner);

        _grantLooksApprovals();
        looks.approve(TRANSFER_MANAGER, HEAL_BASE_COST);

        uint256[] memory agentIds = new uint256[](1);
        agentIds[0] = agentId;

        vm.expectRevert(
            abi.encodePacked(
                IInfiltration.InvalidAgentStatus.selector,
                abi.encode(agentId, IInfiltration.AgentStatus.Wounded)
            )
        );
        infiltration.heal(agentIds);

        vm.stopPrank();

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_heal_RevertIf_HealingMustWaitAtLeastOneRound() public {
        _startGameAndDrawOneRound();

        (uint256[] memory woundedAgentIds, ) = infiltration.getRoundInfo({roundId: 1});

        uint256 agentId = woundedAgentIds[0];
        address agentOwner = infiltration.ownerOf(agentId);

        looks.mint(agentOwner, HEAL_BASE_COST);

        vm.startPrank(agentOwner);

        _grantLooksApprovals();
        looks.approve(TRANSFER_MANAGER, HEAL_BASE_COST);

        uint256[] memory agentIds = new uint256[](1);
        agentIds[0] = agentId;

        vm.expectRevert(IInfiltration.HealingMustWaitAtLeastOneRound.selector);
        infiltration.heal(agentIds);

        vm.stopPrank();

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_heal_RevertIf_MaximumHealingRequestPerRoundExceeded() public {
        _startGameAndDrawOneRound();

        _drawXRounds(1);

        uint256[] memory agentIds = new uint256[](31);

        uint256 totalCost = HEAL_BASE_COST * 31;

        looks.mint(user1, totalCost);

        vm.startPrank(user1);
        _grantLooksApprovals();
        looks.approve(TRANSFER_MANAGER, totalCost);

        vm.expectRevert(IInfiltration.MaximumHealingRequestPerRoundExceeded.selector);
        infiltration.heal(agentIds);
        vm.stopPrank();

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_heal_RevertIf_GameHasNotBegun() public {
        _mintOut();

        uint16 agentId = 69;
        address agentOwner = _ownerOf(agentId);

        looks.mint(agentOwner, HEAL_BASE_COST);

        vm.startPrank(agentOwner);
        _grantLooksApprovals();
        looks.approve(TRANSFER_MANAGER, HEAL_BASE_COST);

        uint256[] memory agentIds = new uint256[](1);
        agentIds[0] = agentId;

        vm.expectRevert(IInfiltration.FrontrunLockIsOn.selector);
        infiltration.heal(agentIds);
        vm.stopPrank();
    }

    function test_heal_RevertIf_FrontrunLockIsOn() public {
        _startGameAndDrawOneRound();

        _startNewRound();

        (uint256[] memory woundedAgentIds, ) = infiltration.getRoundInfo({roundId: 1});

        assertEq(infiltration.costToHeal(woundedAgentIds), HEAL_BASE_COST * woundedAgentIds.length);

        address agentOwner = _ownerOf(woundedAgentIds[0]);

        looks.mint(agentOwner, HEAL_BASE_COST);

        vm.startPrank(agentOwner);
        _grantLooksApprovals();
        looks.approve(TRANSFER_MANAGER, HEAL_BASE_COST);

        uint256[] memory agentIds = new uint256[](1);
        agentIds[0] = woundedAgentIds[0];

        vm.expectRevert(IInfiltration.FrontrunLockIsOn.selector);
        infiltration.heal(agentIds);
        vm.stopPrank();

        invariant_totalAgentsIsEqualToTotalSupply();
    }
}
