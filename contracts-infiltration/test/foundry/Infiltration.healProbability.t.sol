// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IInfiltration} from "../../contracts/interfaces/IInfiltration.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract Infiltration_HealProbability_Test is TestHelpers {
    function setUp() public {
        _forkMainnet();
        _deployInfiltration();
    }

    function test_healProbability() public {
        assertEq(infiltration.healProbability(1), 9900000000);
        assertEq(infiltration.healProbability(2), 9859574468);
        assertEq(infiltration.healProbability(3), 9819148936);
        assertEq(infiltration.healProbability(4), 9778723404);
        assertEq(infiltration.healProbability(5), 9738297872);
        assertEq(infiltration.healProbability(6), 9697872340);
        assertEq(infiltration.healProbability(7), 9657446808);
        assertEq(infiltration.healProbability(8), 9617021276);
        assertEq(infiltration.healProbability(9), 9576595744);
        assertEq(infiltration.healProbability(10), 9536170212);
        assertEq(infiltration.healProbability(11), 9495744680);
        assertEq(infiltration.healProbability(12), 9455319149);
        assertEq(infiltration.healProbability(13), 9414893617);
        assertEq(infiltration.healProbability(14), 9374468085);
        assertEq(infiltration.healProbability(15), 9334042553);
        assertEq(infiltration.healProbability(16), 9293617021);
        assertEq(infiltration.healProbability(17), 9253191489);
        assertEq(infiltration.healProbability(18), 9212765957);
        assertEq(infiltration.healProbability(19), 9172340425);
        assertEq(infiltration.healProbability(20), 9131914893);
        assertEq(infiltration.healProbability(21), 9091489361);
        assertEq(infiltration.healProbability(22), 9051063829);
        assertEq(infiltration.healProbability(23), 9010638297);
        assertEq(infiltration.healProbability(24), 8970212766);
        assertEq(infiltration.healProbability(25), 8929787234);
        assertEq(infiltration.healProbability(26), 8889361702);
        assertEq(infiltration.healProbability(27), 8848936170);
        assertEq(infiltration.healProbability(28), 8808510638);
        assertEq(infiltration.healProbability(29), 8768085106);
        assertEq(infiltration.healProbability(30), 8727659574);
        assertEq(infiltration.healProbability(31), 8687234042);
        assertEq(infiltration.healProbability(32), 8646808510);
        assertEq(infiltration.healProbability(33), 8606382978);
        assertEq(infiltration.healProbability(34), 8565957446);
        assertEq(infiltration.healProbability(35), 8525531914);
        assertEq(infiltration.healProbability(36), 8485106383);
        assertEq(infiltration.healProbability(37), 8444680851);
        assertEq(infiltration.healProbability(38), 8404255319);
        assertEq(infiltration.healProbability(39), 8363829787);
        assertEq(infiltration.healProbability(40), 8323404255);
        assertEq(infiltration.healProbability(41), 8282978723);
        assertEq(infiltration.healProbability(42), 8242553191);
        assertEq(infiltration.healProbability(43), 8202127659);
        assertEq(infiltration.healProbability(44), 8161702127);
        assertEq(infiltration.healProbability(45), 8121276595);
        assertEq(infiltration.healProbability(46), 8080851063);
        assertEq(infiltration.healProbability(47), 8040425531);
        assertEq(infiltration.healProbability(48), 8000000000);
    }

    function test_healProbability_RevertIf_InvalidHealingBlocksDelay() public {
        vm.expectRevert(IInfiltration.InvalidHealingBlocksDelay.selector);
        infiltration.healProbability(0);

        vm.expectRevert(IInfiltration.InvalidHealingBlocksDelay.selector);
        infiltration.healProbability(49);
    }
}
