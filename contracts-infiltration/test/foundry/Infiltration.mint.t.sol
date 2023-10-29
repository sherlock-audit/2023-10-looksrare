// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721A} from "erc721a/contracts/IERC721A.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {IInfiltration} from "../../contracts/interfaces/IInfiltration.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract Infiltration_Mint_Test is TestHelpers {
    function setUp() public {
        _forkMainnet();
        _deployInfiltration();
        _setMintPeriod();
    }

    function test_mint() public {
        vm.deal(user1, PRICE * MAX_MINT_PER_ADDRESS);
        vm.warp(_mintStart());

        expectEmitCheckAll();
        emit ConsecutiveTransfer(1, 100, address(0), user1);

        vm.prank(user1);
        infiltration.mint{value: PRICE * MAX_MINT_PER_ADDRESS}({quantity: MAX_MINT_PER_ADDRESS});

        assertEq(IERC721A(address(infiltration)).balanceOf(user1), MAX_MINT_PER_ADDRESS);
        for (uint16 i = 1; i <= MAX_MINT_PER_ADDRESS; i++) {
            assertEq(_ownerOf(i), user1);
            assertEq(infiltration.tokenURI(i), string(abi.encodePacked(BASE_URI, Strings.toString(i))));
            assertAgentIsTransferrable(i);
        }
    }

    function test_mint_RevertIf_NotInMintPeriod_TooEarly() public asPrankedUser(user1) {
        vm.deal(user1, PRICE);
        vm.warp(_mintStart() - 1 seconds);

        vm.expectRevert(IInfiltration.NotInMintPeriod.selector);
        infiltration.mint{value: PRICE}({quantity: 1});
    }

    function test_mint_RevertIf_NotInMintPeriod_TooLate() public asPrankedUser(user1) {
        vm.deal(user1, PRICE);
        vm.warp(_mintEnd() + 1 seconds);

        vm.expectRevert(IInfiltration.NotInMintPeriod.selector);
        infiltration.mint{value: PRICE}({quantity: 1});
    }

    function test_mint_RevertIf_GameAlreadyBegun() public {
        vm.deal(user1, PRICE * 2);

        vm.warp(_mintStart());
        vm.prank(user1);
        infiltration.mint{value: PRICE}({quantity: 1});

        vm.startPrank(owner);
        vm.warp(_mintEnd());
        infiltration.startGame();
        infiltration.setMintPeriod(0, _mintEnd() + 1 seconds);
        vm.stopPrank();

        vm.prank(user1);
        vm.expectRevert(IInfiltration.GameAlreadyBegun.selector);
        infiltration.mint{value: PRICE}({quantity: 1});
    }

    function test_mint_RevertIf_TooManyMinted_AllInOneGo() public asPrankedUser(user1) {
        vm.warp(_mintStart());

        uint256 quantity = MAX_MINT_PER_ADDRESS + 1;
        vm.deal(user1, PRICE * quantity);
        vm.expectRevert(IInfiltration.TooManyMinted.selector);
        infiltration.mint{value: PRICE * quantity}({quantity: quantity});
    }

    function test_mint_RevertIf_TooManyMinted_InMultipleTransactions() public asPrankedUser(user1) {
        vm.warp(_mintStart());

        vm.deal(user1, PRICE * (MAX_MINT_PER_ADDRESS + 1));
        infiltration.mint{value: PRICE * MAX_MINT_PER_ADDRESS}({quantity: MAX_MINT_PER_ADDRESS});

        vm.expectRevert(IInfiltration.TooManyMinted.selector);
        infiltration.mint{value: PRICE}({quantity: 1});
    }

    function test_mint_RevertIf_InsufficientNativeTokensSupplied() public asPrankedUser(user1) {
        vm.deal(user1, PRICE - 0.01 ether);
        vm.warp(_mintStart());

        vm.expectRevert(IInfiltration.InsufficientNativeTokensSupplied.selector);
        infiltration.mint{value: PRICE - 0.01 ether}({quantity: 1});
    }

    function test_mint_RevertIf_ExceededTotalSupply() public {
        _mintOut();

        address lastBuyer = address(69_420);
        vm.deal(lastBuyer, PRICE);

        vm.expectRevert(IInfiltration.ExceededTotalSupply.selector);
        infiltration.mint{value: PRICE}({quantity: 1});
    }
}
