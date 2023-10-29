// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IInfiltration} from "../../contracts/interfaces/IInfiltration.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract Infiltration_SecondaryPrizePoolShare_Test is TestHelpers {
    function setUp() public {
        _forkMainnet();
        _deployInfiltration();
    }

    function test_secondaryPrizePoolShareBp() public {
        assertEq(infiltration.secondaryPrizePoolShareBp(1), 2_636);
        assertEq(infiltration.secondaryPrizePoolShareBp(2), 1_297);
        assertEq(infiltration.secondaryPrizePoolShareBp(3), 851);
        assertEq(infiltration.secondaryPrizePoolShareBp(4), 628);
        assertEq(infiltration.secondaryPrizePoolShareBp(5), 494);
        assertEq(infiltration.secondaryPrizePoolShareBp(6), 405);
        assertEq(infiltration.secondaryPrizePoolShareBp(7), 342);
        assertEq(infiltration.secondaryPrizePoolShareBp(8), 294);
        assertEq(infiltration.secondaryPrizePoolShareBp(9), 257);
        assertEq(infiltration.secondaryPrizePoolShareBp(10), 227);
        assertEq(infiltration.secondaryPrizePoolShareBp(11), 202);
        assertEq(infiltration.secondaryPrizePoolShareBp(12), 182);
        assertEq(infiltration.secondaryPrizePoolShareBp(13), 165);
        assertEq(infiltration.secondaryPrizePoolShareBp(14), 150);
        assertEq(infiltration.secondaryPrizePoolShareBp(15), 138);
        assertEq(infiltration.secondaryPrizePoolShareBp(16), 126);
        assertEq(infiltration.secondaryPrizePoolShareBp(17), 117);
        assertEq(infiltration.secondaryPrizePoolShareBp(18), 108);
        assertEq(infiltration.secondaryPrizePoolShareBp(19), 100);
        assertEq(infiltration.secondaryPrizePoolShareBp(20), 93);
        assertEq(infiltration.secondaryPrizePoolShareBp(21), 87);
        assertEq(infiltration.secondaryPrizePoolShareBp(22), 81);
        assertEq(infiltration.secondaryPrizePoolShareBp(23), 76);
        assertEq(infiltration.secondaryPrizePoolShareBp(24), 71);
        assertEq(infiltration.secondaryPrizePoolShareBp(25), 66);
        assertEq(infiltration.secondaryPrizePoolShareBp(26), 62);
        assertEq(infiltration.secondaryPrizePoolShareBp(27), 58);
        assertEq(infiltration.secondaryPrizePoolShareBp(28), 55);
        assertEq(infiltration.secondaryPrizePoolShareBp(29), 51);
        assertEq(infiltration.secondaryPrizePoolShareBp(30), 48);
        assertEq(infiltration.secondaryPrizePoolShareBp(31), 45);
        assertEq(infiltration.secondaryPrizePoolShareBp(32), 43);
        assertEq(infiltration.secondaryPrizePoolShareBp(33), 40);
        assertEq(infiltration.secondaryPrizePoolShareBp(34), 38);
        assertEq(infiltration.secondaryPrizePoolShareBp(35), 36);
        assertEq(infiltration.secondaryPrizePoolShareBp(36), 34);
        assertEq(infiltration.secondaryPrizePoolShareBp(37), 31);
        assertEq(infiltration.secondaryPrizePoolShareBp(38), 30);
        assertEq(infiltration.secondaryPrizePoolShareBp(39), 28);
        assertEq(infiltration.secondaryPrizePoolShareBp(40), 26);
        assertEq(infiltration.secondaryPrizePoolShareBp(41), 24);
        assertEq(infiltration.secondaryPrizePoolShareBp(42), 23);
        assertEq(infiltration.secondaryPrizePoolShareBp(43), 21);
        assertEq(infiltration.secondaryPrizePoolShareBp(44), 20);
        assertEq(infiltration.secondaryPrizePoolShareBp(45), 19);
        assertEq(infiltration.secondaryPrizePoolShareBp(46), 17);
        assertEq(infiltration.secondaryPrizePoolShareBp(47), 16);
        assertEq(infiltration.secondaryPrizePoolShareBp(48), 15);
        assertEq(infiltration.secondaryPrizePoolShareBp(49), 14);
        assertEq(infiltration.secondaryPrizePoolShareBp(50), 13);

        uint256 total;
        for (uint256 i = 1; i <= 50; i++) {
            total += infiltration.secondaryPrizePoolShareBp(i);
        }
        assertEq(total, 10_000, "Shares must add up to 100%");
    }

    function testFuzz_secondaryPrizePoolShareAmountMustAddUpToOneHundredPercent(uint256 prizePool) public {
        vm.assume(prizePool >= 0.01 ether && prizePool <= 10_000_000 ether);

        uint256 currentPrizePool = prizePool;
        for (uint256 i = 1; i <= 50; i++) {
            currentPrizePool -= infiltration.secondaryPrizePoolShareAmount(prizePool, i);
        }

        assertLt(currentPrizePool, 50, "Share amounts must add up to 100% (We allow some dust)");
    }
}
