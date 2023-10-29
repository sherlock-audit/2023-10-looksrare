// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TestHelpers} from "./TestHelpers.sol";

contract Infiltration_EscapeFormulas_Test is TestHelpers {
    function setUp() public {
        _forkMainnet();
        _deployInfiltration();
        _setMintPeriod();
        _mintOut();
    }

    function test_escapeMultiplier() public {
        assertEq(infiltration.escapeMultiplier(), 3_000);

        _stubDeadAgents(1_000);
        assertEq(infiltration.escapeMultiplier(), 3_950);

        _stubDeadAgents(2_000);
        assertEq(infiltration.escapeMultiplier(), 4_800);

        _stubDeadAgents(3_000);
        assertEq(infiltration.escapeMultiplier(), 5_550);

        _stubDeadAgents(4_000);
        assertEq(infiltration.escapeMultiplier(), 6_200);

        _stubDeadAgents(5_000);
        assertEq(infiltration.escapeMultiplier(), 6_750);

        _stubDeadAgents(6_000);
        assertEq(infiltration.escapeMultiplier(), 7_200);

        _stubDeadAgents(7_000);
        assertEq(infiltration.escapeMultiplier(), 7_550);

        _stubDeadAgents(8_000);
        assertEq(infiltration.escapeMultiplier(), 7_800);

        _stubDeadAgents(9_000);
        assertEq(infiltration.escapeMultiplier(), 7_950);

        // There can't be 0 remaining agents but we need to test it anyway
        _stubDeadAgents(10_000);
        assertEq(infiltration.escapeMultiplier(), 8_000);
    }

    function testFuzz_escapeMultiplier_MultiplierMustBeWithinBound(uint16 deadAgents) public {
        vm.assume(deadAgents >= 1 && deadAgents <= 10_000);
        _stubDeadAgents(deadAgents);
        assertGe(infiltration.escapeMultiplier(), 3_000);
        assertLe(infiltration.escapeMultiplier(), 8_000);
    }

    function test_escapeRewardSplitForSecondaryPrizePool() public {
        assertEq(infiltration.escapeRewardSplitForSecondaryPrizePool(), 2_000);

        _stubDeadAgents(1_000);
        assertEq(infiltration.escapeRewardSplitForSecondaryPrizePool(), 2_808);

        _stubDeadAgents(2_000);
        assertEq(infiltration.escapeRewardSplitForSecondaryPrizePool(), 3_616);

        _stubDeadAgents(3_000);
        assertEq(infiltration.escapeRewardSplitForSecondaryPrizePool(), 4_424);

        _stubDeadAgents(4_000);
        assertEq(infiltration.escapeRewardSplitForSecondaryPrizePool(), 5_232);

        _stubDeadAgents(5_000);
        assertEq(infiltration.escapeRewardSplitForSecondaryPrizePool(), 6_040);

        _stubDeadAgents(6_000);
        assertEq(infiltration.escapeRewardSplitForSecondaryPrizePool(), 6_848);

        _stubDeadAgents(7_000);
        assertEq(infiltration.escapeRewardSplitForSecondaryPrizePool(), 7_656);

        _stubDeadAgents(8_000);
        assertEq(infiltration.escapeRewardSplitForSecondaryPrizePool(), 8_464);

        _stubDeadAgents(9_000);
        assertEq(infiltration.escapeRewardSplitForSecondaryPrizePool(), 9_272);

        _stubDeadAgents(9_900);
        assertEq(infiltration.escapeRewardSplitForSecondaryPrizePool(), 10_000);

        // There can't be 0 remaining agents but we need to test it anyway
        _stubDeadAgents(10_000);
        assertEq(infiltration.escapeRewardSplitForSecondaryPrizePool(), 10_000);
    }

    function testFuzz_escapeRewardSplitForSecondaryPrizePool_MultiplierMustBeWithinBound(uint16 deadAgents) public {
        vm.assume(deadAgents >= 1 && deadAgents <= 10_000);
        _stubDeadAgents(deadAgents);
        assertGe(infiltration.escapeRewardSplitForSecondaryPrizePool(), 2_000);
        assertLe(infiltration.escapeRewardSplitForSecondaryPrizePool(), 10_000);
    }
}
