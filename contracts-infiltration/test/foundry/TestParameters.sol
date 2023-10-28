// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TestParameters {
    uint256 public constant MAX_SUPPLY = 10_000;
    uint256 public constant MAX_MINT_PER_ADDRESS = 100;
    uint256 public constant PRICE = 0.05 ether;
    uint256 public constant BLOCKS_PER_ROUND = 50;
    uint256 public constant AGENTS_TO_WOUND_PER_ROUND_IN_BASIS_POINTS = 20;
    uint256 public constant ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD = 48;
    uint256 public constant HEAL_BASE_COST = 50 ether;

    bytes32 internal constant KEY_HASH = hex"8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef";
    uint64 internal constant SUBSCRIPTION_ID = 734;
    address internal constant VRF_COORDINATOR = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    address internal constant SUBSCRIPTION_ADMIN = 0xB5a9e5a319c7fDa551a30BE592c77394bF935c6f;

    address internal constant TRANSFER_MANAGER = 0x00000000000ea4af05656C17b90f4d64AdD29e1d;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant LOOKS = 0xf4d2888d29D722226FafA5d9B24F9164c092421E;

    address internal constant UNISWAP_ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address internal constant UNISWAP_QUOTER = 0x61fFE014bA17989E743c5F6cB21bF9697530B21e;

    string internal constant BASE_URI = "https://looksrare.org/the-infiltration/";
}
