// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";
import {IERC721A} from "erc721a/contracts/IERC721A.sol";

import {Infiltration} from "../../contracts/Infiltration.sol";
import {IInfiltration} from "../../contracts/interfaces/IInfiltration.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract Infiltration_SetUpState_Test is TestHelpers {
    event MintPeriodUpdated(uint256 mintStart, uint256 mintEnd);

    function setUp() public {
        _forkMainnet();
        _deployInfiltration();
    }

    function test_setUpState() public {
        assertEq(infiltration.owner(), owner);
        assertEq(infiltration.name(), "Infiltration");
        assertEq(infiltration.symbol(), "INFILTRATION");
        assertEq(infiltration.PRICE(), PRICE);
        assertEq(infiltration.MAX_SUPPLY(), MAX_SUPPLY);
        assertEq(infiltration.BLOCKS_PER_ROUND(), BLOCKS_PER_ROUND);
        assertEq(infiltration.AGENTS_TO_WOUND_PER_ROUND_IN_BASIS_POINTS(), AGENTS_TO_WOUND_PER_ROUND_IN_BASIS_POINTS);
        assertEq(infiltration.ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD(), ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD);
        assertEq(infiltration.HEAL_BASE_COST(), HEAL_BASE_COST);

        assertEq(infiltration.mintStart(), 0);
        assertEq(infiltration.mintEnd(), 0);

        assertEq(infiltration.protocolFeeRecipient(), protocolFeeRecipient);
        assertEq(infiltration.protocolFeeBp(), 1_500);

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
        assertEq(activeAgents, 0);
        assertEq(woundedAgents, 0);
        assertEq(healingAgents, 0);
        assertEq(deadAgents, 0);
        assertEq(escapedAgents, 0);
        assertEq(currentRoundId, 0);
        assertEq(currentRoundBlockNumber, 0);
        assertEq(randomnessLastRequestedAt, 0);
        assertEq(prizePool, 0);
        assertEq(secondaryPrizePool, 0);
        assertEq(secondaryLooksPrizePool, 0);
    }

    function test_setUpState_RevertIf_WoundedAgentIdsPerRoundExceeded() public {
        IInfiltration.ConstructorCalldata memory constructorCalldata = _constructorCalldata();
        constructorCalldata.agentsToWoundPerRoundInBasisPoints = 31; // 10,000 * 0.31% = 31 (> 30)

        vm.expectRevert(IInfiltration.WoundedAgentIdsPerRoundExceeded.selector);
        infiltration = new Infiltration(constructorCalldata);
    }

    function test_setUpState_RevertIf_InvalidMaxSupply_TooHigh() public {
        IInfiltration.ConstructorCalldata memory constructorCalldata = _constructorCalldata();
        constructorCalldata.maxSupply = uint256(type(uint16).max) + 1;

        vm.expectRevert(IInfiltration.InvalidMaxSupply.selector);
        infiltration = new Infiltration(constructorCalldata);
    }

    function test_setUpState_RevertIf_InvalidMaxSupply_TooLow() public {
        IInfiltration.ConstructorCalldata memory constructorCalldata = _constructorCalldata();
        constructorCalldata.maxSupply = 49;

        vm.expectRevert(IInfiltration.InvalidMaxSupply.selector);
        infiltration = new Infiltration(constructorCalldata);

        constructorCalldata.maxSupply = 50;

        vm.expectRevert(IInfiltration.InvalidMaxSupply.selector);
        infiltration = new Infiltration(constructorCalldata);
    }

    function test_setUpState_RevertIf_RoundsToBeWoundedBeforeDeadTooLow() public {
        IInfiltration.ConstructorCalldata memory constructorCalldata = _constructorCalldata();
        constructorCalldata.roundsToBeWoundedBeforeDead = 2;

        vm.expectRevert(IInfiltration.RoundsToBeWoundedBeforeDeadTooLow.selector);
        infiltration = new Infiltration(constructorCalldata);
    }

    function test_setMintPeriod() public {
        expectEmitCheckAll();
        emit MintPeriodUpdated(_mintStart(), _mintEnd());

        _setMintPeriod();

        assertEq(infiltration.mintStart(), _mintStart());
        assertEq(infiltration.mintEnd(), _mintEnd());
    }

    function test_setMintPeriod_ExtendMintStart() public {
        _setMintPeriod();

        expectEmitCheckAll();
        emit MintPeriodUpdated(_mintStart() + 12 hours, _mintEnd());

        vm.prank(owner);
        infiltration.setMintPeriod(_mintStart() + 12 hours, _mintEnd());

        assertEq(infiltration.mintStart(), _mintStart() + 12 hours);
        assertEq(infiltration.mintEnd(), _mintEnd());
    }

    function test_setMintPeriod_OnlySettingMintEnd() public {
        _setMintPeriod();

        expectEmitCheckAll();
        emit MintPeriodUpdated(_mintStart(), _mintEnd() + 1 seconds);

        vm.prank(owner);
        infiltration.setMintPeriod(0, _mintEnd() + 1 seconds);

        assertEq(infiltration.mintStart(), _mintStart());
        assertEq(infiltration.mintEnd(), _mintEnd() + 1 seconds);
    }

    function test_setMintPeriod_RevertIf_NotOwner() public {
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        infiltration.setMintPeriod(_mintStart(), _mintEnd());
    }

    function test_setMintPeriod_RevertIf_MintStartIsInThePast() public asPrankedUser(owner) {
        vm.warp(86_400);
        vm.expectRevert(IInfiltration.MintStartIsInThePast.selector);
        infiltration.setMintPeriod(uint40(block.timestamp - 1 seconds), _mintEnd());
    }

    function test_setMintPeriod_RevertIf_EndPeriodIsBeforeStartPeriod() public asPrankedUser(owner) {
        vm.expectRevert(IInfiltration.InvalidMintPeriod.selector);
        infiltration.setMintPeriod(_mintStart(), _mintStart());

        vm.expectRevert(IInfiltration.InvalidMintPeriod.selector);
        infiltration.setMintPeriod(_mintStart(), _mintStart() - 1 seconds);
    }

    function test_setMintPeriod_RevertIf_MintAlreadyStarted() public {
        _setMintPeriod();

        vm.warp(_mintStart());

        vm.prank(owner);
        vm.expectRevert(IInfiltration.MintAlreadyStarted.selector);
        infiltration.setMintPeriod(_mintStart() + 12 hours, _mintEnd());
    }

    function test_setMintPeriod_RevertIf_MintCanOnlyBeExtended_MintEndIsNotInTheFuture() public asPrankedUser(owner) {}

    function test_setMintPeriod_RevertIf_MintCanOnlyBeExtended_NewMintEndIsEarlierThanCurrentMintEnd() public {
        _setMintPeriod();

        vm.prank(owner);
        vm.expectRevert(IInfiltration.MintCanOnlyBeExtended.selector);
        infiltration.setMintPeriod(_mintStart(), _mintEnd() - 1 seconds);
    }

    function test_safeTransferFrom_RevertIf_TransferToZeroAddress() public {
        _setMintPeriod();

        vm.warp(_mintStart());

        vm.deal(user1, PRICE);

        vm.startPrank(user1);
        infiltration.mint{value: PRICE}({quantity: 1});
        assertEq(IERC721A(address(infiltration)).balanceOf(user1), 1);

        vm.expectRevert(IERC721A.TransferToZeroAddress.selector);
        infiltration.safeTransferFrom(user1, address(0), 1);
        vm.stopPrank();
    }

    function test_updateProtocolFeeBp_RevertIf_Immutable() public {
        vm.expectRevert(IInfiltration.Immutable.selector);
        infiltration.updateProtocolFeeBp(2_500);
    }

    function test_updateProtocolFeeRecipient_RevertIf_Immutable() public {
        vm.expectRevert(IInfiltration.Immutable.selector);
        infiltration.updateProtocolFeeRecipient(user1);
    }
}
