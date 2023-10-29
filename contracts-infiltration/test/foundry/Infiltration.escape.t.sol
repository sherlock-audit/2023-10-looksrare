// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";
import {ITransferManager} from "@looksrare/contracts-transfer-manager/contracts/interfaces/ITransferManager.sol";

import {IERC721A} from "erc721a/contracts/IERC721A.sol";

import {IInfiltration} from "../../contracts/interfaces/IInfiltration.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract Infiltration_Escape_Test is TestHelpers {
    event Escaped(uint256 roundId, uint256[] agentIds, uint256[] rewards);

    function setUp() public {
        _forkMainnet();
        _deployInfiltration();
        _setMintPeriod();
    }

    function test_escape() public {
        _startGameAndDrawOneRound();

        uint256 startingPrizePool = 425 ether;
        uint256[] memory agentIds = new uint256[](100);

        for (uint256 i; i < 100; i++) {
            agentIds[i] = i + 301;
        }

        address agentOwner = _ownerOf(agentIds[0]);
        uint256 expectedReward = 1.299218654570935416 ether;

        uint256[] memory expectedRewards = new uint256[](100);
        expectedRewards[0] = 12750000000000000;
        expectedRewards[1] = 12750714071407140;
        expectedRewards[2] = 12755678730316448;
        expectedRewards[3] = 12760643785424279;
        expectedRewards[4] = 12765609236634376;
        expectedRewards[5] = 12770575083850463;
        expectedRewards[6] = 12775541326976243;
        expectedRewards[7] = 12780508055372669;
        expectedRewards[8] = 12785475179551832;
        expectedRewards[9] = 12790442699417379;
        expectedRewards[10] = 12795410614872936;
        expectedRewards[11] = 12800378925822111;
        expectedRewards[12] = 12805347721780402;
        expectedRewards[13] = 12810316913105167;
        expectedRewards[14] = 12815286499699956;
        expectedRewards[15] = 12820256481468302;
        expectedRewards[16] = 12825226858313717;
        expectedRewards[17] = 12830197719906218;
        expectedRewards[18] = 12835168976448453;
        expectedRewards[19] = 12840140627843880;
        expectedRewards[20] = 12845112673995933;
        expectedRewards[21] = 12850085114808030;
        expectedRewards[22] = 12855058040104687;
        expectedRewards[23] = 12860031359933865;
        expectedRewards[24] = 12865005074198924;
        expectedRewards[25] = 12869979182803205;
        expectedRewards[26] = 12874953685650028;
        expectedRewards[27] = 12879928582642696;
        expectedRewards[28] = 12884903963791093;
        expectedRewards[29] = 12889879738957583;
        expectedRewards[30] = 12894855908045413;
        expectedRewards[31] = 12899832470957807;
        expectedRewards[32] = 12904809427597971;
        expectedRewards[33] = 12909786868130242;
        expectedRewards[34] = 12914764702262343;
        expectedRewards[35] = 12919742929897427;
        expectedRewards[36] = 12924721550938621;
        expectedRewards[37] = 12929700565289038;
        expectedRewards[38] = 12934680063267439;
        expectedRewards[39] = 12939659954426935;
        expectedRewards[40] = 12944640238670580;
        expectedRewards[41] = 12949620915901410;
        expectedRewards[42] = 12954601986022438;
        expectedRewards[43] = 12959583539506833;
        expectedRewards[44] = 12964565485753112;
        expectedRewards[45] = 12969547824664234;
        expectedRewards[46] = 12974530556143139;
        expectedRewards[47] = 12979513680092745;
        expectedRewards[48] = 12984497287140603;
        expectedRewards[49] = 12989481286530659;
        expectedRewards[50] = 12994465678165779;
        expectedRewards[51] = 12999450461948805;
        expectedRewards[52] = 13004435637782563;
        expectedRewards[53] = 13009421205569858;
        expectedRewards[54] = 13014407256123463;
        expectedRewards[55] = 13019393698501875;
        expectedRewards[56] = 13024380532607841;
        expectedRewards[57] = 13029367758344093;
        expectedRewards[58] = 13034355375613339;
        expectedRewards[59] = 13039343475382682;
        expectedRewards[60] = 13044331966556102;
        expectedRewards[61] = 13049320849036251;
        expectedRewards[62] = 13054310122725765;
        expectedRewards[63] = 13059299787527258;
        expectedRewards[64] = 13064289934562139;
        expectedRewards[65] = 13069280472579892;
        expectedRewards[66] = 13074271401483076;
        expectedRewards[67] = 13079262721174232;
        expectedRewards[68] = 13084254431555878;
        expectedRewards[69] = 13089246623903704;
        expectedRewards[70] = 13094239206812726;
        expectedRewards[71] = 13099232180185409;
        expectedRewards[72] = 13104225543924197;
        expectedRewards[73] = 13109219297931515;
        expectedRewards[74] = 13114213533637307;
        expectedRewards[75] = 13119208159482147;
        expectedRewards[76] = 13124203175368403;
        expectedRewards[77] = 13129198581198426;
        expectedRewards[78] = 13134194376874544;
        expectedRewards[79] = 13139190562299071;
        expectedRewards[80] = 13144187229087023;
        expectedRewards[81] = 13149184285493673;
        expectedRewards[82] = 13154181731421275;
        expectedRewards[83] = 13159179566772066;
        expectedRewards[84] = 13164177791448260;
        expectedRewards[85] = 13169176497219078;
        expectedRewards[86] = 13174175592185403;
        expectedRewards[87] = 13179175076249395;
        expectedRewards[88] = 13184174949313194;
        expectedRewards[89] = 13189175211278923;
        expectedRewards[90] = 13194175954069975;
        expectedRewards[91] = 13199177085632872;
        expectedRewards[92] = 13204178605869678;
        expectedRewards[93] = 13209180514682440;
        expectedRewards[94] = 13214182811973184;
        expectedRewards[95] = 13219185589819456;
        expectedRewards[96] = 13224188756013436;
        expectedRewards[97] = 13229192310457098;
        expectedRewards[98] = 13234196253052392;
        expectedRewards[99] = 13239200583701251;

        assertEq(infiltration.escapeReward(agentIds), expectedReward);

        expectEmitCheckAll();
        emit Escaped(2, agentIds, expectedRewards);

        vm.prank(agentOwner);
        infiltration.escape(agentIds);

        _assertAgentIdsHaveEscaped(agentIds);

        vm.expectRevert(
            abi.encodePacked(
                IInfiltration.InvalidAgentStatus.selector,
                abi.encode(agentIds[0], IInfiltration.AgentStatus.Active)
            )
        );
        infiltration.escapeReward(agentIds);

        assertEq(agentOwner.balance, expectedReward);
        assertEq(address(infiltration).balance, startingPrizePool - expectedReward);

        (
            uint16 activeAgents,
            ,
            ,
            ,
            uint16 escapedAgents,
            ,
            ,
            ,
            uint256 prizePool,
            uint256 secondaryPrizePool,

        ) = infiltration.gameInfo();
        assertEq(prizePool, 423.096587585754502780 ether);
        assertEq(secondaryPrizePool, 0.604193759674561804 ether);
        assertEq(activeAgents, MAX_SUPPLY - 20 - 100);
        assertEq(escapedAgents, 100);

        assertEq(infiltration.agentsAlive(), MAX_SUPPLY - 100);

        for (uint256 i; i < 100; i++) {
            agentIds[i] = i + 401;
        }

        address agentOwner2 = _ownerOf(agentIds[0]);
        uint256 expectedReward2 = 1.349012728357292986 ether;

        uint256[] memory expectedRewards2 = new uint256[](100);
        expectedRewards2[0] = 13244205302305587;
        expectedRewards2[1] = 13249210501127890;
        expectedRewards2[2] = 13254216087775171;
        expectedRewards2[3] = 13259222062149287;
        expectedRewards2[4] = 13264228424152075;
        expectedRewards2[5] = 13269235173685356;
        expectedRewards2[6] = 13274242403165708;
        expectedRewards2[7] = 13279250020045865;
        expectedRewards2[8] = 13284258024227589;
        expectedRewards2[9] = 13289266415612623;
        expectedRewards2[10] = 13294275194102691;
        expectedRewards2[11] = 13299284452268441;
        expectedRewards2[12] = 13304294097408350;
        expectedRewards2[13] = 13309304129424088;
        expectedRewards2[14] = 13314314548217303;
        expectedRewards2[15] = 13319325353689625;
        expectedRewards2[16] = 13324336638565740;
        expectedRewards2[17] = 13329348309989900;
        expectedRewards2[18] = 13334360367863678;
        expectedRewards2[19] = 13339372812088631;
        expectedRewards2[20] = 13344385642566294;
        expectedRewards2[21] = 13349398952175363;
        expectedRewards2[22] = 13354412647905892;
        expectedRewards2[23] = 13359426729659361;
        expectedRewards2[24] = 13364441197337231;
        expectedRewards2[25] = 13369456050840943;
        expectedRewards2[26] = 13374471290071919;
        expectedRewards2[27] = 13379487008093634;
        expectedRewards2[28] = 13384503111711138;
        expectedRewards2[29] = 13389519600825796;
        expectedRewards2[30] = 13394536475338956;
        expectedRewards2[31] = 13399553735151947;
        expectedRewards2[32] = 13404571473482194;
        expectedRewards2[33] = 13409589596980608;
        expectedRewards2[34] = 13414608105548461;
        expectedRewards2[35] = 13419626999087008;
        expectedRewards2[36] = 13424646277497482;
        expectedRewards2[37] = 13429666034151231;
        expectedRewards2[38] = 13434686175545058;
        expectedRewards2[39] = 13439706701580139;
        expectedRewards2[40] = 13444727612157636;
        expectedRewards2[41] = 13449748907178687;
        expectedRewards2[42] = 13450487085555303;
        expectedRewards2[43] = 13455509115438969;
        expectedRewards2[44] = 13460531529640199;
        expectedRewards2[45] = 13465554328060068;
        expectedRewards2[46] = 13470577510599635;
        expectedRewards2[47] = 13475601170921891;
        expectedRewards2[48] = 13480625215231653;
        expectedRewards2[49] = 13485649643429923;
        expectedRewards2[50] = 13490674455417683;
        expectedRewards2[51] = 13495699651095896;
        expectedRewards2[52] = 13500725230365507;
        expectedRewards2[53] = 13505751287074151;
        expectedRewards2[54] = 13510777727241776;
        expectedRewards2[55] = 13515804550769270;
        expectedRewards2[56] = 13520831757557503;
        expectedRewards2[57] = 13525859347507326;
        expectedRewards2[58] = 13530887414620212;
        expectedRewards2[59] = 13535915864762083;
        expectedRewards2[60] = 13540944697833734;
        expectedRewards2[61] = 13545973913735942;
        expectedRewards2[62] = 13551003512369463;
        expectedRewards2[63] = 13556033587889580;
        expectedRewards2[64] = 13561064046008218;
        expectedRewards2[65] = 13566094886626081;
        expectedRewards2[66] = 13571126109643849;
        expectedRewards2[67] = 13576157714962187;
        expectedRewards2[68] = 13581189796890156;
        expectedRewards2[69] = 13586222260985716;
        expectedRewards2[70] = 13591255107149476;
        expectedRewards2[71] = 13596288335282024;
        expectedRewards2[72] = 13601321945283929;
        expectedRewards2[73] = 13606356031618005;
        expectedRewards2[74] = 13611390499688273;
        expectedRewards2[75] = 13616425349395249;
        expectedRewards2[76] = 13621460580639428;
        expectedRewards2[77] = 13626496193321287;
        expectedRewards2[78] = 13631532187341283;
        expectedRewards2[79] = 13636568657346685;
        expectedRewards2[80] = 13641605508556835;
        expectedRewards2[81] = 13646642740872132;
        expectedRewards2[82] = 13651680354192962;
        expectedRewards2[83] = 13656718348419686;
        expectedRewards2[84] = 13661756818353259;
        expectedRewards2[85] = 13666795669059151;
        expectedRewards2[86] = 13671834900437670;
        expectedRewards2[87] = 13676874512389106;
        expectedRewards2[88] = 13681914504813729;
        expectedRewards2[89] = 13686954972666146;
        expectedRewards2[90] = 13691995820857987;
        expectedRewards2[91] = 13697037049289467;
        expectedRewards2[92] = 13702078657860784;
        expectedRewards2[93] = 13707120646472113;
        expectedRewards2[94] = 13712163110231684;
        expectedRewards2[95] = 13717205953897319;
        expectedRewards2[96] = 13722249177369138;
        expectedRewards2[97] = 13727292780547248;
        expectedRewards2[98] = 13732336763331730;
        expectedRewards2[99] = 13737381125622651;

        expectEmitCheckAll();
        emit Escaped(2, agentIds, expectedRewards2);

        assertEq(infiltration.escapeReward(agentIds), expectedReward2);

        vm.prank(agentOwner2);
        infiltration.escape(agentIds);

        _assertAgentIdsHaveEscaped(agentIds);

        vm.expectRevert(
            abi.encodePacked(
                IInfiltration.InvalidAgentStatus.selector,
                abi.encode(agentIds[0], IInfiltration.AgentStatus.Active)
            )
        );
        infiltration.escapeReward(agentIds);

        assertEq(agentOwner2.balance, expectedReward2);
        assertEq(address(infiltration).balance, startingPrizePool - expectedReward - expectedReward2);

        (activeAgents, , , , escapedAgents, , , , prizePool, secondaryPrizePool, ) = infiltration.gameInfo();
        assertEq(prizePool, 421.124998231966580336 ether);
        assertEq(secondaryPrizePool, 1.226770385105191262 ether);
        assertEq(activeAgents, MAX_SUPPLY - 20 - 200);
        assertEq(escapedAgents, 200);

        assertEq(infiltration.agentsAlive(), MAX_SUPPLY - 200);
        assertEq(
            prizePool + secondaryPrizePool + expectedReward + expectedReward2,
            startingPrizePool,
            "The total should always add up to the original prize pool"
        );
        assertGt(expectedReward2, expectedReward, "Later escape should have higher reward");

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_escape_DownTo1ActiveAgent() public {
        _downTo50ActiveAgents();
        _downToXActiveAgent(2);

        uint256[] memory agentIds = new uint256[](1);
        IInfiltration.Agent memory agent = infiltration.getAgent(1);
        agentIds[0] = agent.agentId;
        address agentOwner = IERC721A(address(infiltration)).ownerOf(agent.agentId);

        IInfiltration.Agent memory wonAgent = infiltration.getAgent(2);

        expectEmitCheckAll();
        emit Won(2_271, wonAgent.agentId);

        vm.prank(agentOwner);
        infiltration.escape(agentIds);

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_escape_RevertIf_AgentIdBeyongTotalSupply() public {
        _startGameAndDrawOneRound();

        uint256 agentId = infiltration.totalSupply() + 1;
        uint256[] memory agentIds = new uint256[](1);
        agentIds[0] = agentId;

        vm.expectRevert(IERC721A.OwnerQueryForNonexistentToken.selector);
        infiltration.escape(agentIds);

        agentId = uint256(type(uint16).max) + 1;
        agentIds[0] = agentId;

        vm.expectRevert(IERC721A.OwnerQueryForNonexistentToken.selector);
        infiltration.escape(agentIds);
    }

    function test_escape_RevertIf_DuplicatedAgentIds() public {
        _startGameAndDrawOneRound();

        uint16 agentId = 301;
        uint256[] memory agentIds = new uint256[](2);
        agentIds[0] = agentId;
        agentIds[1] = agentId;

        address agentOwner = _ownerOf(agentId);

        vm.prank(agentOwner);
        vm.expectRevert(
            abi.encodePacked(
                IInfiltration.InvalidAgentStatus.selector,
                abi.encode(agentIds[0], IInfiltration.AgentStatus.Active)
            )
        );
        infiltration.escape(agentIds);

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_escape_RevertIf_NoAgentsProvided() public {
        _startGameAndDrawOneRound();
        vm.expectRevert(IInfiltration.NoAgentsProvided.selector);
        infiltration.escape(new uint256[](0));

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_escape_RevertIf_NoAgentsLeft() public {
        _downTo1ActiveAgent();

        IInfiltration.Agent memory agent = infiltration.getAgent(1);

        uint256[] memory agentIds = new uint256[](1);
        agentIds[0] = agent.agentId;

        vm.prank(_ownerOf(agent.agentId));
        vm.expectRevert(IInfiltration.NoAgentsLeft.selector);
        infiltration.escape(agentIds);

        vm.expectRevert(IInfiltration.NoAgentsLeft.selector);
        infiltration.escapeReward(agentIds);

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_escape_RevertIf_NotAgentOwner() public {
        _startGameAndDrawOneRound();

        uint256[] memory agentIds = new uint256[](1);
        agentIds[0] = 1;

        vm.prank(user4);
        vm.expectRevert(IInfiltration.NotAgentOwner.selector);
        infiltration.escape(agentIds);

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_escape_RevertIf_InvalidAgentStatus() public {
        _startGameAndDrawOneRound();

        uint256[] memory agentIds = new uint256[](1);
        agentIds[0] = 301;

        vm.startPrank(user4);

        infiltration.escape(agentIds);

        vm.expectRevert(
            abi.encodePacked(
                IInfiltration.InvalidAgentStatus.selector,
                abi.encode(agentIds[0], IInfiltration.AgentStatus.Active)
            )
        );
        infiltration.escape(agentIds);

        vm.stopPrank();

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function test_escape_RevertIf_GameHasNotBegun() public {
        _mintOut();
        vm.expectRevert(IInfiltration.FrontrunLockIsOn.selector);
        infiltration.escape(new uint256[](1));
    }

    function test_escape_RevertIf_FrontrunLockIsOn() public {
        _startGameAndDrawOneRound();

        _startNewRound();

        uint256[] memory agentIds = new uint256[](100);

        for (uint256 i; i < 100; i++) {
            agentIds[i] = i + 301;
        }

        vm.prank(user4);
        vm.expectRevert(IInfiltration.FrontrunLockIsOn.selector);
        infiltration.escape(agentIds);

        invariant_totalAgentsIsEqualToTotalSupply();
    }

    function _assertAgentIdsHaveEscaped(uint256[] memory agentIds) private {
        for (uint256 i; i < agentIds.length; i++) {
            uint256 index = infiltration.agentIndex(agentIds[i]);
            IInfiltration.Agent memory agent = infiltration.getAgent(index);

            assertEq(agent.agentId, agentIds[i]);
            assertEq(uint8(agent.status), uint8(IInfiltration.AgentStatus.Escaped));
            assertEq(agent.woundedAt, 0);
            assertEq(agent.healCount, 0);

            assertAgentIsNotTransferrable(agent.agentId, IInfiltration.AgentStatus.Escaped);

            // Swapped agent from the end of the mapping
            IInfiltration.Agent memory lastAgent = infiltration.getAgent(agent.agentId);

            assertEq(lastAgent.agentId, index);

            // Swapped agents are either active or wounded
            if (lastAgent.status == IInfiltration.AgentStatus.Active) {
                assertEq(uint8(lastAgent.status), uint8(IInfiltration.AgentStatus.Active));
                assertEq(lastAgent.woundedAt, 0);
            } else {
                assertEq(uint8(lastAgent.status), uint8(IInfiltration.AgentStatus.Wounded));
                assertEq(lastAgent.woundedAt, 18_090_639);
            }

            assertEq(lastAgent.healCount, 0);
        }
    }
}
