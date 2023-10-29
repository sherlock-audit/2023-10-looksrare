// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TestHelpers} from "./TestHelpers.sol";

contract Infiltration_EmergencyWithdraw_Test is TestHelpers {
    event EmergencyWithdrawal(uint256 ethAmount, uint256 looksAmount);

    function setUp() public {
        _forkMainnet();
        _deployInfiltration();
        _setMintPeriod();

        vm.deal(owner, 0);
        deal(address(looks), owner, 0);

        // Mint some LOOKS to the contract so we don't have to heal to get LOOKS
        looks.mint(address(infiltration), 69_420 ether);
    }

    function test_emergencyWithdraw_ConditionOne() public {
        _startGameAndDrawOneRound();
        _stubDeadAgents(69);

        expectEmitCheckAll();
        emit EmergencyWithdrawal(425 ether, 69_420 ether);

        vm.prank(owner);
        infiltration.emergencyWithdraw();

        assertEq(owner.balance, 425 ether);
        assertEq(looks.balanceOf(owner), 69_420 ether);
    }

    function test_emergencyWithdraw_ConditionTwo() public {
        _startGameAndDrawOneRound();

        vm.roll(block.number + 10_800 + 1);

        expectEmitCheckAll();
        emit EmergencyWithdrawal(425 ether, 69_420 ether);

        vm.prank(owner);
        infiltration.emergencyWithdraw();

        assertEq(owner.balance, 425 ether);
        assertEq(looks.balanceOf(owner), 69_420 ether);

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_emergencyWithdraw_ConditionThree() public {
        _mintOut();

        vm.warp(infiltration.mintEnd() + 36 hours + 1 seconds);

        expectEmitCheckAll();
        emit EmergencyWithdrawal(500 ether, 69_420 ether);

        vm.prank(owner);
        infiltration.emergencyWithdraw();

        assertEq(owner.balance, 500 ether);
        assertEq(looks.balanceOf(owner), 69_420 ether);
    }

    function test_emergencyWithdraw_NoneOfTheConditionsAreMet() public {
        _startGameAndDrawOneRound();

        vm.prank(owner);
        infiltration.emergencyWithdraw();

        assertEq(owner.balance, 0);
        assertEq(looks.balanceOf(owner), 0);

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_emergencyWithdraw_AgentsCountDoesNotMatchTotalSupply_ButGameHasNotStarted() public {
        _mintOut();

        vm.prank(owner);
        infiltration.emergencyWithdraw();

        assertEq(owner.balance, 0);
        assertEq(looks.balanceOf(owner), 0);
    }
}
