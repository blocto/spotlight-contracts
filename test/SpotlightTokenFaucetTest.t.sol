// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import {SpotlightTokenFaucet} from "../src/spotlight-token-faucet/SpotlightTokenFaucet.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SampleToken is ERC20 {
    constructor() ERC20("Sample Token", "SMT") {
        _mint(msg.sender, 2_000e18);
    }
}

contract SpotlightTokenFaucetTest is Test {
    error OwnableUnauthorizedAccount(address account);

    address private _sampleTokenOwner;
    address private _sampleTokenAddr;
    ERC20 private _sampleToken;

    address private _faucetOwner;
    address private _faucetAddr;
    SpotlightTokenFaucet private _faucet;

    function setUp() public {
        _sampleTokenOwner = makeAddr("sampleTokenOwner");
        vm.startPrank(_sampleTokenOwner);
        _sampleToken = new SampleToken();
        _sampleTokenAddr = address(_sampleToken);
        vm.stopPrank();

        _faucetOwner = makeAddr("owner");
        vm.startPrank(_faucetOwner);
        _faucet = new SpotlightTokenFaucet(_sampleTokenAddr);
        _faucetAddr = address(_faucet);
        vm.stopPrank();

        vm.startPrank(_sampleTokenOwner);
        _sampleToken.transfer(_faucetAddr, 2_000e18);
        vm.stopPrank();
    }

    function testSpotlightTokenFaucetConstructor() public view {
        assertEq(_faucet.owner(), _faucetOwner);
        assertEq(_faucet.tokenAddress(), _sampleTokenAddr);
        assertEq(_faucet.faucetClaimAmount(), 1_000e18);
        assertEq(_faucet.isFaucetActive(), true);
        assertEq(_faucet.isWaitTimeActive(), true);
        assertEq(_faucet.waitTime(), 1 days);

        assertEq(_sampleToken.balanceOf(_faucetAddr), 2_000e18);
    }

    function testNotOwnerSetFaucetActive() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _faucet.setFaucetActive(false);
    }

    function testNotOwnerSetFaucetClaimAmount() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _faucet.setFaucetClaimAmount(2_000e18);
    }

    function testOwnerSetFaucetActive() public {
        vm.startPrank(_faucetOwner);
        _faucet.setFaucetActive(false);
        vm.startPrank(_faucetOwner);
        assertEq(_faucet.isFaucetActive(), false);

        vm.startPrank(_faucetOwner);
        _faucet.setFaucetActive(true);
        vm.startPrank(_faucetOwner);
        assertEq(_faucet.isFaucetActive(), true);
    }

    function testClaimWhenFaucetInactive() public {
        vm.startPrank(_faucetOwner);
        _faucet.setFaucetActive(false);
        vm.expectRevert("SpotlightTokenFaucet: faucet is not active");
        _faucet.claimToken();
    }

    function testNotOwnerSetWaitTimeActive() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _faucet.setWaitTimeActive(false);
    }

    function testOwnerSetWaitTimeActive() public {
        vm.startPrank(_faucetOwner);
        _faucet.setWaitTimeActive(false);
        vm.startPrank(_faucetOwner);
        assertEq(_faucet.isWaitTimeActive(), false);

        vm.startPrank(_faucetOwner);
        _faucet.setWaitTimeActive(true);
        vm.startPrank(_faucetOwner);
        assertEq(_faucet.isWaitTimeActive(), true);
    }

    function testNotOwnerSetWaitTime() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _faucet.setWaitTime(10 minutes);
    }

    function testOwnerSetWaitTime() public {
        vm.startPrank(_faucetOwner);
        _faucet.setWaitTime(10 minutes);
        vm.startPrank(_faucetOwner);
        assertEq(_faucet.waitTime(), 10 minutes);
    }

    function testNotOwnerDistrubuteToken() public {
        address notOwner = makeAddr("notOwner");
        address recipient = makeAddr("recipient");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _faucet.distributeToken(recipient, 1_000e18);
    }

    function testOwnerDistributeToken() public {
        address recipient = makeAddr("recipient");
        uint256 balanceBefore = _sampleToken.balanceOf(recipient);
        uint256 lastClaimTimestampBefore = _faucet.lastClaimTimestamp(recipient);
        uint256 secondsUintilNextClaimBefore = _faucet.secondsUntilNextClaim(recipient);

        vm.startPrank(_faucetOwner);
        _faucet.distributeToken(recipient, 1_000e18);
        vm.startPrank(_faucetOwner);

        assertEq(_sampleToken.balanceOf(recipient), balanceBefore + 1_000e18);
        assertEq(_faucet.lastClaimTimestamp(recipient), lastClaimTimestampBefore);
        assertEq(_faucet.secondsUntilNextClaim(recipient), secondsUintilNextClaimBefore);
    }

    function testClaim() public {
        address claimer = makeAddr("claimer");
        uint256 balanceBefore = _sampleToken.balanceOf(claimer);

        vm.startPrank(claimer);
        _faucet.claimToken();
        vm.stopPrank();

        assertEq(_sampleToken.balanceOf(claimer), balanceBefore + _faucet.faucetClaimAmount());
        assertEq(_faucet.lastClaimTimestamp(claimer), block.timestamp);
        assertEq(_faucet.secondsUntilNextClaim(claimer), 1 days);

        // claim again after wait time passed
        vm.warp(block.timestamp + 1 days);
        vm.startPrank(claimer);
        _faucet.claimToken();
        vm.stopPrank();
        assertEq(_sampleToken.balanceOf(claimer), balanceBefore + 2 * _faucet.faucetClaimAmount());
    }

    function testClaimWhenFaucetTurnnedOff() public {
        address claimer = makeAddr("claimer");

        vm.startPrank(_faucetOwner);
        _faucet.setFaucetActive(false);
        vm.stopPrank();

        vm.startPrank(claimer);
        vm.expectRevert("SpotlightTokenFaucet: faucet is not active");
        _faucet.claimToken();
    }

    function testClaimBeforeWaitTimePass() public {
        address claimer = makeAddr("claimer");

        vm.startPrank(claimer);
        _faucet.claimToken();
        vm.stopPrank();

        vm.startPrank(claimer);
        vm.expectRevert("SpotlightTokenFaucet: wait time has not passed");
        _faucet.claimToken();
    }

    function testClaimAgainWhenWaitTimeInactive() public {
        address claimer = makeAddr("claimer");

        vm.startPrank(_faucetOwner);
        _faucet.setWaitTimeActive(false);
        vm.stopPrank();

        vm.startPrank(claimer);
        _faucet.claimToken();
        vm.stopPrank();

        vm.startPrank(claimer);
        _faucet.claimToken();
        vm.stopPrank();

        assertEq(_faucet.lastClaimTimestamp(claimer), block.timestamp);
        assertEq(_faucet.secondsUntilNextClaim(claimer), 0);
    }

    function testDistributeOverBalance() public {
        address recipient = makeAddr("recipient");

        vm.startPrank(_faucetOwner);
        vm.expectRevert();
        _faucet.distributeToken(recipient, 2_001e18);
        vm.startPrank(_faucetOwner);
    }
}
