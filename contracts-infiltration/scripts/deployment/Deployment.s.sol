// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ITransferManager} from "@looksrare/contracts-transfer-manager/contracts/interfaces/ITransferManager.sol";

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";

// Core contracts
import {Infiltration} from "../../contracts/Infiltration.sol";
import {InfiltrationPeriphery} from "../../contracts/InfiltrationPeriphery.sol";
import {IInfiltration} from "../../contracts/interfaces/IInfiltration.sol";

// Create2 factory interface
import {IImmutableCreate2Factory} from "../../contracts/interfaces/IImmutableCreate2Factory.sol";

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract Deployment is Script {
    IImmutableCreate2Factory private constant IMMUTABLE_CREATE2_FACTORY =
        IImmutableCreate2Factory(0x0000000000FFe8B47B3e2130213B802212439497);

    error ChainIdInvalid(uint256 chainId);

    function run() external {
        uint256 chainId = block.chainid;
        uint256 deployerPrivateKey;
        address owner;
        address protocolFeeRecipient;
        address wrappedNativeToken;
        address transferManager;
        bytes32 keyHash;
        address vrfCoordinator;
        uint64 subscriptionId;
        address looks;
        uint256 agentsToBeWoundedPerRoundInBasisPoints;
        uint256 price;
        string memory baseURI;
        uint256 maxSupply;
        uint256 maxMintPerAddress;
        uint256 blocksPerRound;
        uint256 roundsToBeWoundedBeforeDead;

        if (chainId == 1) {
            deployerPrivateKey = vm.envUint("MAINNET_KEY");
            wrappedNativeToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            keyHash = hex"8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef";
            subscriptionId = 734;
            vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
            owner = 0xB5a9e5a319c7fDa551a30BE592c77394bF935c6f;
            protocolFeeRecipient = 0xB5a9e5a319c7fDa551a30BE592c77394bF935c6f;
            transferManager = 0x00000000000ea4af05656C17b90f4d64AdD29e1d;
            looks = 0xf4d2888d29D722226FafA5d9B24F9164c092421E;
            agentsToBeWoundedPerRoundInBasisPoints = 20;
            price = 0.05 ether;
            baseURI = "https://api.looksrare.org/api/v1/infiltration/agent/";
            maxSupply = 10_000;
            maxMintPerAddress = 100;
            blocksPerRound = 50;
            roundsToBeWoundedBeforeDead = 48;
        } else if (chainId == 11155111) {
            deployerPrivateKey = vm.envUint("TESTNET_KEY");
            wrappedNativeToken = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
            keyHash = hex"474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c";
            subscriptionId = 1_122;
            vrfCoordinator = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
            owner = 0xF332533bF5d0aC462DC8511067A8122b4DcE2B57;
            protocolFeeRecipient = 0x50F0787Ed7C9091aBCa1D667fDBCcd85EA68C38C;
            transferManager = 0x8B43b6C4601FaCF70Fe17D057b3912Bde0206CFB;
            looks = 0xa68c2CaA3D45fa6EBB95aA706c70f49D3356824E;
            agentsToBeWoundedPerRoundInBasisPoints = 120;
            price = 0.0005 ether;
            baseURI = "https://api-sepolia.looksrare.org/api/v1/infiltration/agent/";
            maxSupply = 2_500;
            maxMintPerAddress = 250;
            blocksPerRound = 25;
            roundsToBeWoundedBeforeDead = 24;
        } else {
            revert ChainIdInvalid(chainId);
        }

        uint256 healBaseCost = 50 ether;
        uint16 protocolFeeBp = 1_500;

        IInfiltration.ConstructorCalldata memory constructorCalldata = IInfiltration.ConstructorCalldata({
            owner: owner,
            name: "LooksRare Infiltration",
            symbol: "LRAGENT",
            price: price,
            maxSupply: maxSupply,
            maxMintPerAddress: maxMintPerAddress,
            blocksPerRound: blocksPerRound,
            agentsToWoundPerRoundInBasisPoints: agentsToBeWoundedPerRoundInBasisPoints,
            roundsToBeWoundedBeforeDead: roundsToBeWoundedBeforeDead,
            looks: looks,
            keyHash: keyHash,
            vrfCoordinator: vrfCoordinator,
            subscriptionId: subscriptionId,
            transferManager: transferManager,
            healBaseCost: healBaseCost,
            protocolFeeRecipient: protocolFeeRecipient,
            protocolFeeBp: protocolFeeBp,
            weth: wrappedNativeToken,
            baseURI: baseURI
        });

        vm.startBroadcast(deployerPrivateKey);

        if (chainId == 1) {
            IMMUTABLE_CREATE2_FACTORY.safeCreate2({
                salt: vm.envBytes32("INFILTRATION_SALT"),
                initializationCode: abi.encodePacked(type(Infiltration).creationCode, abi.encode(constructorCalldata))
            });

            // TODO: Replace address(0) with Infiltration address
            IMMUTABLE_CREATE2_FACTORY.safeCreate2({
                salt: vm.envBytes32("INFILTRATION_PERIPHERY_SALT"),
                initializationCode: abi.encodePacked(
                    type(InfiltrationPeriphery).creationCode,
                    abi.encode(transferManager, address(0), wrappedNativeToken, looks)
                )
            });
        } else {
            Infiltration infiltration = new Infiltration(constructorCalldata);
            VRFCoordinatorV2Interface(vrfCoordinator).addConsumer(subscriptionId, address(infiltration));
            ITransferManager(transferManager).allowOperator(address(infiltration));

            new InfiltrationPeriphery(
                transferManager,
                address(infiltration),
                0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E,
                0xEd1f6473345F45b75F8179591dd5bA1888cf2FB3,
                wrappedNativeToken,
                looks
            );

            uint40 mintStart = uint40(block.timestamp + 1 minutes);
            uint40 mintEnd = mintStart + 72 hours + 5 minutes;
            infiltration.setMintPeriod(mintStart, mintEnd);
        }

        vm.stopBroadcast();
    }
}
