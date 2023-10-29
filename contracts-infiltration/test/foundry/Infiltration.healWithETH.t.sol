// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";
import {ITransferManager} from "@looksrare/contracts-transfer-manager/contracts/interfaces/ITransferManager.sol";
import {IERC721A} from "erc721a/contracts/IERC721A.sol";
import {IERC20} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC20.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import {Infiltration} from "../../contracts/Infiltration.sol";
import {InfiltrationPeriphery} from "../../contracts/InfiltrationPeriphery.sol";
import {IInfiltration} from "../../contracts/interfaces/IInfiltration.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract Infiltration_HealWithETH_Test is TestHelpers {
    InfiltrationPeriphery private infiltrationPeriphery;

    function setUp() public {
        _forkMainnet();

        IInfiltration.ConstructorCalldata memory constructorCalldata = _constructorCalldata();
        constructorCalldata.looks = LOOKS;
        infiltration = new Infiltration(constructorCalldata);

        vm.prank(SUBSCRIPTION_ADMIN);
        VRFCoordinatorV2Interface(VRF_COORDINATOR).addConsumer(SUBSCRIPTION_ID, address(infiltration));

        vm.prank(SUBSCRIPTION_ADMIN);
        ITransferManager(TRANSFER_MANAGER).allowOperator(address(infiltration));

        infiltrationPeriphery = new InfiltrationPeriphery(
            TRANSFER_MANAGER,
            address(infiltration),
            UNISWAP_ROUTER,
            UNISWAP_QUOTER,
            WETH,
            LOOKS
        );

        _setMintPeriod();
    }

    function testFuzz_heal(uint256 extraValue) public {
        vm.assume(extraValue < 100 ether);

        _startGameAndDrawOneRound();

        _drawXRounds(1);

        (uint256[] memory woundedAgentIds, ) = infiltration.getRoundInfo({roundId: 1});

        uint256 costToHealInLOOKS = HEAL_BASE_COST * woundedAgentIds.length;
        assertEq(infiltration.costToHeal(woundedAgentIds), costToHealInLOOKS);

        uint256 costToHealWithETH = infiltrationPeriphery.costToHeal(woundedAgentIds);
        assertEq(costToHealWithETH, 0.034556088942325354 ether);

        _healWithETH(woundedAgentIds, costToHealWithETH, extraValue);

        assertAgentIdsAreHealing(woundedAgentIds);

        (, uint256[] memory healingAgentIds) = infiltration.getRoundInfo({roundId: 1});
        assertAgentIdsAreHealing(healingAgentIds);

        (, uint16 woundedAgents, uint16 healingAgents, , , , , , , , ) = infiltration.gameInfo();
        assertEq(woundedAgents, 19);
        assertEq(healingAgents, woundedAgentIds.length);

        assertEq(IERC20(LOOKS).balanceOf(address(infiltration)), costToHealInLOOKS);
        assertEq(address(infiltrationPeriphery).balance, 0);
        assertEq(user1.balance, extraValue);

        vm.expectRevert(
            abi.encodePacked(
                IInfiltration.InvalidAgentStatus.selector,
                abi.encode(woundedAgentIds[0], IInfiltration.AgentStatus.Wounded)
            )
        );
        infiltrationPeriphery.costToHeal(woundedAgentIds);

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function _healWithETH(uint256[] memory woundedAgentIds, uint256 costToHealInETH, uint256 extraValue) private {
        uint256[] memory costs = new uint256[](woundedAgentIds.length);
        for (uint256 i; i < woundedAgentIds.length; i++) {
            costs[i] = HEAL_BASE_COST;
        }

        expectEmitCheckAll();
        emit HealRequestSubmitted(3, woundedAgentIds, costs);

        vm.deal(user1, costToHealInETH + extraValue);

        vm.prank(user1);
        infiltrationPeriphery.heal{value: costToHealInETH + extraValue}(woundedAgentIds);
    }
}
