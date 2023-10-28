// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITransferManager} from "@looksrare/contracts-transfer-manager/contracts/interfaces/ITransferManager.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import {Infiltration} from "../../contracts/Infiltration.sol";
import {IInfiltration} from "../../contracts/interfaces/IInfiltration.sol";

import {AssertionHelpers} from "./AssertionHelpers.sol";
import {ChainlinkHelpers} from "./ChainlinkHelpers.sol";
import {TestParameters} from "./TestParameters.sol";
import {MockERC20} from "../mock/MockERC20.sol";

abstract contract TestHelpers is AssertionHelpers, ChainlinkHelpers, TestParameters {
    address public user1 = address(11);
    address public user2 = address(12);
    address public user3 = address(13);
    address public user4 = address(14);
    address public user5 = address(15);
    address public owner = address(69);
    address public protocolFeeRecipient = address(420);

    uint256 public blockNumber = 18_090_639;

    MockERC20 internal looks;

    modifier asPrankedUser(address user) {
        vm.startPrank(user);
        _;
        vm.stopPrank();
    }

    function _forkMainnet() internal {
        vm.createSelectFork("mainnet", blockNumber);
    }

    function _constructorCalldata()
        internal
        view
        returns (IInfiltration.ConstructorCalldata memory constructorCalldata)
    {
        constructorCalldata = IInfiltration.ConstructorCalldata({
            owner: owner,
            name: "Infiltration",
            symbol: "INFILTRATION",
            price: PRICE,
            maxSupply: MAX_SUPPLY,
            maxMintPerAddress: MAX_MINT_PER_ADDRESS,
            blocksPerRound: BLOCKS_PER_ROUND,
            agentsToWoundPerRoundInBasisPoints: AGENTS_TO_WOUND_PER_ROUND_IN_BASIS_POINTS,
            roundsToBeWoundedBeforeDead: ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD,
            looks: address(looks),
            keyHash: KEY_HASH,
            vrfCoordinator: VRF_COORDINATOR,
            subscriptionId: SUBSCRIPTION_ID,
            transferManager: TRANSFER_MANAGER,
            healBaseCost: HEAL_BASE_COST,
            protocolFeeRecipient: protocolFeeRecipient,
            protocolFeeBp: 1_500,
            weth: WETH,
            baseURI: BASE_URI
        });
    }

    function _deployInfiltration() internal {
        looks = new MockERC20();
        infiltration = new Infiltration(_constructorCalldata());

        vm.prank(SUBSCRIPTION_ADMIN);
        VRFCoordinatorV2Interface(VRF_COORDINATOR).addConsumer(SUBSCRIPTION_ID, address(infiltration));

        vm.prank(SUBSCRIPTION_ADMIN);
        ITransferManager(TRANSFER_MANAGER).allowOperator(address(infiltration));
    }

    function _mintStart() internal view returns (uint40) {
        return uint40(block.timestamp + 1 days);
    }

    function _mintEnd() internal view returns (uint40) {
        return uint40(block.timestamp + 2 days);
    }

    function _setMintPeriod() internal {
        vm.prank(owner);
        infiltration.setMintPeriod(_mintStart(), _mintEnd());
    }

    function _grantLooksApprovals() internal {
        (, address msgSender, ) = vm.readCallers();
        address[] memory operators = new address[](1);
        operators[0] = address(infiltration);
        if (!ITransferManager(TRANSFER_MANAGER).hasUserApprovedOperator(msgSender, address(infiltration))) {
            ITransferManager(TRANSFER_MANAGER).grantApprovals(operators);
        }
    }

    function _mintOut() internal {
        vm.warp(_mintStart());

        uint160 startingUser = 11;

        for (uint160 i = startingUser; i < (MAX_SUPPLY / MAX_MINT_PER_ADDRESS + startingUser); i++) {
            vm.deal(address(i), PRICE * MAX_MINT_PER_ADDRESS);
            vm.prank(address(i));
            infiltration.mint{value: PRICE * MAX_MINT_PER_ADDRESS}({quantity: MAX_MINT_PER_ADDRESS});
        }
    }

    function _randomWords() internal pure returns (uint256[] memory randomWords) {
        randomWords = new uint256[](1);
        randomWords[0] = 69_420;
    }

    function _computeVrfRequestId(uint64 roundId) internal view returns (uint256 requestId) {
        requestId = _computeVrfRequestId({
            keyHash: KEY_HASH,
            sender: address(infiltration),
            subId: SUBSCRIPTION_ID,
            nonce: roundId + 1
        });
    }

    function _heal(uint256 roundId, uint256[] memory woundedAgentIds) internal {
        for (uint256 i; i < woundedAgentIds.length; i++) {
            address agentOwner = _ownerOf(woundedAgentIds[i]);

            looks.mint(agentOwner, HEAL_BASE_COST);

            vm.startPrank(agentOwner);
            _grantLooksApprovals();
            looks.approve(TRANSFER_MANAGER, HEAL_BASE_COST);

            uint256[] memory agentIds = new uint256[](1);
            agentIds[0] = woundedAgentIds[i];

            uint256[] memory costs = new uint256[](1);
            costs[0] = HEAL_BASE_COST;

            expectEmitCheckAll();
            emit HealRequestSubmitted(roundId, agentIds, costs);

            infiltration.heal(agentIds);
            vm.stopPrank();
        }
    }

    function _startGameAndDrawOneRound() internal {
        uint256[] memory randomWords = _randomWords();

        _mintOut();

        expectEmitCheckAll();
        emit RoundStarted(1);

        vm.prank(owner);
        infiltration.startGame();

        expectEmitCheckAll();
        emit RoundStarted(2);

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(infiltration)).rawFulfillRandomWords(_computeVrfRequestId(1), randomWords);
    }

    function _downTo50ActiveAgents() internal {
        _startGameAndDrawOneRound();
        _drawXRounds(2_221);

        (uint16 activeAgents, , , , , , , , , , ) = infiltration.gameInfo();
        assertEq(activeAgents, 50, "Active agents should be 50");
    }

    function _downTo1ActiveAgent() internal {
        _downTo50ActiveAgents();
        _downToXActiveAgent(1);
    }

    function _downToXActiveAgent(uint256 x) internal {
        for (uint256 i; i < 50 - x; i++) {
            uint256[] memory randomWords = _randomWords();
            randomWords[0] += uint256(keccak256(abi.encodePacked(i)));

            _startNewRound();

            uint256 requestId = _computeVrfRequestId(uint64(_getCurrentRoundId()));
            vm.prank(VRF_COORDINATOR);
            VRFConsumerBaseV2(address(infiltration)).rawFulfillRandomWords(requestId, randomWords);
        }
    }

    function _startNewRound() internal {
        blockNumber += BLOCKS_PER_ROUND;
        vm.roll(blockNumber);
        infiltration.startNewRound();
    }

    function _drawXRounds(uint256 x) internal {
        uint256[] memory randomWords = _randomWords();

        uint40 startingRoundId = _getCurrentRoundId();

        for (uint256 i; i < x; i++) {
            _startNewRound();

            uint40 roundId = _getCurrentRoundId();

            assertNotEq(_getRandomnessLastRequestedAt(), 0, "Randomness last requested at should not be 0");

            randomWords[0] += i;
            uint256 requestId = _computeVrfRequestId(roundId);

            vm.prank(VRF_COORDINATOR);
            VRFConsumerBaseV2(address(infiltration)).rawFulfillRandomWords(requestId, randomWords);

            assertEq(roundId + 1, _getCurrentRoundId(), "Round ID should increment");
            assertEq(_getRandomnessLastRequestedAt(), 0, "Randomness last requested at should be 0");
        }

        assertEq(startingRoundId + x, _getCurrentRoundId(), "Round ID should increment");
    }

    function _getCurrentRoundId() internal view returns (uint40 currentRoundId) {
        (, , , , , currentRoundId, , , , , ) = infiltration.gameInfo();
    }

    function _getRandomnessLastRequestedAt() internal view returns (uint40 randomnessLastRequestedAt) {
        (, , , , , , , randomnessLastRequestedAt, , , ) = infiltration.gameInfo();
    }

    function _stubDeadAgents(uint16 amount) internal {
        uint256 gameInfoSlot = 19;
        uint256 value = uint256(vm.load(address(infiltration), bytes32(gameInfoSlot)));
        value &= ~(uint256(0xffff) << 48);
        value |= uint256(amount) << 48;
        vm.store(address(infiltration), bytes32(gameInfoSlot), bytes32(value));

        assertEq(infiltration.totalSupply(), MAX_SUPPLY);
        assertEq(infiltration.agentsAlive(), MAX_SUPPLY - amount);
        (, , , uint16 deadAgents, , , , , , , ) = infiltration.gameInfo();
        assertEq(deadAgents, amount);
    }

    function _stubRandomnessRequestExistence(uint256 requestId, bool exists) internal {
        bytes32 slot = bytes32(keccak256(abi.encode(requestId, uint256(14))));
        uint256 value = exists ? 1 : 0;

        vm.store(address(infiltration), slot, bytes32(value));
    }
}
