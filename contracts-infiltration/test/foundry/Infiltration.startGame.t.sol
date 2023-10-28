// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";

import {IInfiltration} from "../../contracts/interfaces/IInfiltration.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract Infiltration_StartGame_Test is TestHelpers {
    function setUp() public {
        _forkMainnet();
        _deployInfiltration();
        _setMintPeriod();
    }

    function test_startGame() public {
        _mintOut();

        expectEmitCheckAll();
        emit RandomnessRequested(1, _computeVrfRequestId(1));

        vm.prank(owner);
        infiltration.startGame();

        (
            uint16 activeAgents,
            uint16 woundedAgents,
            uint16 healingAgents,
            uint16 deadAgents,
            uint16 escapedAgents,
            uint40 currentRoundId,
            uint40 currentRoundBlockNumber,
            uint40 randomnessLastRequestedAt,
            uint256 prizePool,
            uint256 secondaryPrizePool,
            uint256 secondaryLooksPrizePool
        ) = infiltration.gameInfo();
        assertEq(activeAgents, MAX_SUPPLY);
        assertEq(woundedAgents, 0);
        assertEq(healingAgents, 0);
        assertEq(deadAgents, 0);
        assertEq(escapedAgents, 0);
        assertEq(currentRoundId, 1);
        assertEq(currentRoundBlockNumber, 0);
        assertEq(randomnessLastRequestedAt, block.timestamp);
        assertEq(prizePool, 425 ether);
        assertEq(secondaryPrizePool, 0);
        assertEq(secondaryLooksPrizePool, 0);

        assertEq(address(infiltration).balance, 425 ether);
        assertEq(protocolFeeRecipient.balance, 75 ether);

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_startGame_RevertIf_GameAlreadyBegun() public {
        _mintOut();
        vm.prank(owner);
        infiltration.startGame();

        vm.prank(owner);
        vm.expectRevert(IInfiltration.GameAlreadyBegun.selector);
        infiltration.startGame();

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_startGame_RevertIf_NotOwner() public {
        _mintOut();

        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        infiltration.startGame();
    }

    function test_startGame_RevertIf_StillMinting() public {
        vm.warp(_mintEnd() - 1 seconds);

        uint160 startingUser = 11;

        for (uint160 i = startingUser; i < MAX_SUPPLY / MAX_MINT_PER_ADDRESS + startingUser - 1; i++) {
            vm.deal(address(i), PRICE * MAX_MINT_PER_ADDRESS);
            vm.prank(address(i));
            infiltration.mint{value: PRICE * MAX_MINT_PER_ADDRESS}({quantity: MAX_MINT_PER_ADDRESS});
        }

        vm.expectRevert(IInfiltration.StillMinting.selector);
        vm.prank(owner);
        infiltration.startGame();
    }
}
