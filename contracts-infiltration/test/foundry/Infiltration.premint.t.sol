// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721A} from "erc721a/contracts/IERC721A.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";

import {IInfiltration} from "../../contracts/interfaces/IInfiltration.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract Infiltration_Premint_Test is TestHelpers {
    uint256 private constant QUANTITY = MAX_MINT_PER_ADDRESS + 1;

    function setUp() public {
        _forkMainnet();
        _deployInfiltration();
    }

    function test_premint() public {
        vm.deal(owner, PRICE * QUANTITY);

        expectEmitCheckAll();
        emit ConsecutiveTransfer(1, QUANTITY, address(0), user1);

        vm.prank(owner);
        infiltration.premint{value: PRICE * QUANTITY}({to: user1, quantity: QUANTITY});

        assertEq(owner.balance, 0);
        assertEq(IERC721A(address(infiltration)).balanceOf(user1), QUANTITY);
        for (uint16 i = 1; i <= QUANTITY; i++) {
            assertEq(_ownerOf(i), user1);
            assertEq(infiltration.tokenURI(i), string(abi.encodePacked(BASE_URI, Strings.toString(i))));
            assertAgentIsTransferrable(i);
        }
    }

    function test_premint_RevertIf_NotOwner() public {
        vm.deal(owner, PRICE * QUANTITY);
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        infiltration.premint{value: PRICE * QUANTITY}({to: user1, quantity: QUANTITY});
    }

    function test_premint_RevertIf_GameAlreadyStarted() public {
        _setMintPeriod();

        vm.warp(_mintStart());

        uint160 startingUser = 11;

        for (uint160 i = startingUser; i < (MAX_SUPPLY / MAX_MINT_PER_ADDRESS + startingUser) - 1; i++) {
            vm.deal(address(i), PRICE * MAX_MINT_PER_ADDRESS);
            vm.prank(address(i));
            infiltration.mint{value: PRICE * MAX_MINT_PER_ADDRESS}({quantity: MAX_MINT_PER_ADDRESS});
        }

        vm.warp(_mintEnd() + 1 seconds);

        vm.startPrank(owner);

        infiltration.startGame();

        vm.deal(owner, PRICE * MAX_MINT_PER_ADDRESS);

        vm.expectRevert(IInfiltration.GameAlreadyBegun.selector);
        infiltration.premint{value: PRICE * MAX_MINT_PER_ADDRESS}({to: user1, quantity: MAX_MINT_PER_ADDRESS});

        vm.stopPrank();
    }

    function test_mint_RevertIf_InsufficientNativeTokensSupplied() public asPrankedUser(owner) {
        vm.deal(owner, PRICE * MAX_MINT_PER_ADDRESS);
        vm.expectRevert(IInfiltration.InsufficientNativeTokensSupplied.selector);
        infiltration.premint{value: PRICE * MAX_MINT_PER_ADDRESS}({to: user1, quantity: QUANTITY});
    }

    function test_premint_RevertIf_ExceededTotalSupply() public {
        _setMintPeriod();
        _mintOut();

        vm.deal(owner, PRICE * QUANTITY);

        vm.prank(owner);
        vm.expectRevert(IInfiltration.ExceededTotalSupply.selector);
        infiltration.premint{value: PRICE * QUANTITY}({to: user1, quantity: QUANTITY});
    }
}
