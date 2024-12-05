// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import {SpotlightUSDCFaucet} from "../src/spotlight-token-faucet/SpotlightUSDCFaucet.sol";
import {SpotlightTokenFaucet} from "../src/spotlight-token-faucet/SpotlightTokenFaucet.sol";

contract SpotlightTokenFaucetTest is Test {
    address private _owner;
    address private _sUSDCAddr;
    SpotlightTokenFaucet private _sUSDC;

    function setUp() public {
        _owner = makeAddr("owner");

        vm.startPrank(_owner);
        _sUSDC = new SpotlightUSDCFaucet();
        _sUSDCAddr = address(_sUSDC);
        vm.stopPrank();
    }

    function testSpotlightTokenFaucetConstructor() public view {
        assertEq(_sUSDC.owner(), _owner);
        assertEq(_sUSDC.name(), "Spotlight USDC");
        assertEq(_sUSDC.symbol(), "SUSDC");
        assertEq(_sUSDC.faucetClaimAmount(), 1_000e18);
        assertEq(_sUSDC.isFaucetActive(), true);
        assertEq(_sUSDC.isWaitTimeActive(), true);
        assertEq(_sUSDC.waitTime(), 1 days);
    }

    function testNotOwnerSetFaucetActive() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _sUSDC.setFaucetActive(false);
    }

    function testOwnerSetFaucetActive() public {
        vm.startPrank(_owner);
        _sUSDC.setFaucetActive(false);
        vm.startPrank(_owner);
        assertEq(_sUSDC.isFaucetActive(), false);

        vm.startPrank(_owner);
        _sUSDC.setFaucetActive(true);
        vm.startPrank(_owner);
        assertEq(_sUSDC.isFaucetActive(), true);
    }

    function testClaimWhenFaucetInactive() public {
        vm.startPrank(_owner);
        _sUSDC.setFaucetActive(false);
        vm.expectRevert("SpotlightTokenFaucet: faucet is not active");
        _sUSDC.claimToken();
    }

    function testNotOwnerSetWaitTimeActive() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _sUSDC.setWaitTimeActive(false);
    }

    function testOwnerSetWaitTimeActive() public {
        vm.startPrank(_owner);
        _sUSDC.setWaitTimeActive(false);
        vm.startPrank(_owner);
        assertEq(_sUSDC.isWaitTimeActive(), false);

        vm.startPrank(_owner);
        _sUSDC.setWaitTimeActive(true);
        vm.startPrank(_owner);
        assertEq(_sUSDC.isWaitTimeActive(), true);
    }

    function testNotOwnerSetWaitTime() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _sUSDC.setWaitTime(10 minutes);
    }

    function testOwnerSetWaitTime() public {
        vm.startPrank(_owner);
        _sUSDC.setWaitTime(10 minutes);
        vm.startPrank(_owner);
        assertEq(_sUSDC.waitTime(), 10 minutes);
    }

    function testNotOwnerDistrubuteToken() public {
        address notOwner = makeAddr("notOwner");
        address recipient = makeAddr("recipient");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _sUSDC.distributeToken(recipient, 1_000e18);
    }

    function testOwnerDistributeToken() public {
        address recipient = makeAddr("recipient");
        uint256 balanceBefore = _sUSDC.balanceOf(recipient);
        uint256 lastClaimTimestampBefore = _sUSDC.lastClaimTimestamp(recipient);
        uint256 secondsUintilNextClaimBefore = _sUSDC.secondsUntilNextClaim(recipient);

        vm.startPrank(_owner);
        _sUSDC.distributeToken(recipient, 1_000e18);
        vm.startPrank(_owner);

        assertEq(_sUSDC.balanceOf(recipient), balanceBefore + 1_000e18);
        assertEq(_sUSDC.lastClaimTimestamp(recipient), lastClaimTimestampBefore);
        assertEq(_sUSDC.secondsUntilNextClaim(recipient), secondsUintilNextClaimBefore);
    }

    function testClaim() public {
        address claimer = makeAddr("claimer");
        uint256 balanceBefore = _sUSDC.balanceOf(claimer);

        vm.startPrank(claimer);
        _sUSDC.claimToken();
        vm.stopPrank();

        assertEq(_sUSDC.balanceOf(claimer), balanceBefore + _sUSDC.faucetClaimAmount());
        assertEq(_sUSDC.lastClaimTimestamp(claimer), block.timestamp);
        assertEq(_sUSDC.secondsUntilNextClaim(claimer), 1 days);

        // claim again after wait time passed
        vm.warp(block.timestamp + 1 days);
        vm.startPrank(claimer);
        _sUSDC.claimToken();
        vm.stopPrank();
        assertEq(_sUSDC.balanceOf(claimer), balanceBefore + 2 * _sUSDC.faucetClaimAmount());
    }

    function testClaimWhenFaucetTurnnedOff() public {
        address claimer = makeAddr("claimer");

        vm.startPrank(_owner);
        _sUSDC.setFaucetActive(false);
        vm.stopPrank();

        vm.startPrank(claimer);
        vm.expectRevert("SpotlightTokenFaucet: faucet is not active");
        _sUSDC.claimToken();
    }

    function testClaimBeforeWaitTimePass() public {
        address claimer = makeAddr("claimer");

        vm.startPrank(claimer);
        _sUSDC.claimToken();
        vm.stopPrank();

        vm.startPrank(claimer);
        vm.expectRevert("SpotlightTokenFaucet: wait time has not passed");
        _sUSDC.claimToken();
    }

    function testClaimAgainWhenWaitTimeInactive() public {
        address claimer = makeAddr("claimer");

        vm.startPrank(_owner);
        _sUSDC.setWaitTimeActive(false);
        vm.stopPrank();

        vm.startPrank(claimer);
        _sUSDC.claimToken();
        vm.stopPrank();

        vm.startPrank(claimer);
        _sUSDC.claimToken();
        vm.stopPrank();

        assertEq(_sUSDC.lastClaimTimestamp(claimer), block.timestamp);
        assertEq(_sUSDC.secondsUntilNextClaim(claimer), 0);
    }
}
