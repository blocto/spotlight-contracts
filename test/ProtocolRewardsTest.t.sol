// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import {SpotlightProtocolRewards} from "../src/spotlight-protocol-rewards/SpotlightProtocolRewards.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISpotlightProtocolRewards} from "../src/spotlight-protocol-rewards/ISpotlightProtocolRewards.sol";

contract SpotlightProtocolRewardsTest is Test {
    address constant IPA_ID = 0x359EcA9F3C4cCdB7C10Dd4D9410EaD52Ef9B430A;
    address constant IPA_TOKEN_CONTRACT = 0xfAa933848Bd4C9AAb7Ee25Dd5c80E4dCCa678307;
    uint256 constant IPA_TOKEN_ID = 70;
    address constant IPA_TOKEN_OWNER = 0x1B961DcCa88EAb760e57EC09A90206E3640f53C5;

    uint256 constant DEFAULT_BALANCE = 1 ether;
    uint256 constant REWARD_AMOUNT = 1 ether;

    address private _user;
    address private _owner;
    SpotlightProtocolRewards private _protocolRewards;

    function setUp() public {
        _user = makeAddr("user");
        vm.deal(_user, DEFAULT_BALANCE);
        _owner = makeAddr("owner");
        vm.deal(_owner, DEFAULT_BALANCE);
        vm.prank(_owner);
        _protocolRewards = new SpotlightProtocolRewards();
    }

    function testOwnerIsDeployer() public view {
        assertEq(_protocolRewards.owner(), _owner);
    }

    function testIsWithdrawEnabledDefaultReturnsFalse() public view {
        bool isEnabled = _protocolRewards.isWithdrawEnabled();
        assertFalse(isEnabled);
    }

    function testSetWithdrawEnabledSuccessWithOwner() public {
        vm.prank(_owner);
        _protocolRewards.setWithdrawEnabled(true);
        assertTrue(_protocolRewards.isWithdrawEnabled());
    }

    function testSetWithdrawEnabledRevertsWhenNotOwner() public {
        address nonOwner = makeAddr("nonOwner");
        vm.prank(nonOwner);
        vm.expectRevert();
        _protocolRewards.setWithdrawEnabled(true);
    }

    function testDepositSuccess() public {
        vm.startPrank(_user);
        vm.expectEmit(false, false, false, true);
        emit ISpotlightProtocolRewards.Deposit(IPA_TOKEN_CONTRACT, IPA_TOKEN_ID, REWARD_AMOUNT);
        _protocolRewards.deposit{value: REWARD_AMOUNT}(IPA_ID);
        vm.stopPrank();
    }

    function testDepositRevertsWhenToAddressZero() public {
        vm.startPrank(_user);
        vm.expectRevert(SpotlightProtocolRewards.AddressZero.selector);
        _protocolRewards.deposit{value: REWARD_AMOUNT}(address(0));
        vm.stopPrank();
    }

    function testDepositRevertsWhenAmountZero() public {
        vm.startPrank(_user);
        vm.expectRevert(SpotlightProtocolRewards.AmountZero.selector);
        _protocolRewards.deposit{value: 0}(IPA_ID);
        vm.stopPrank();
    }

    function testDepositRevertsWhenInvalidReturnData() public {
        address nonIpaId = makeAddr("nonIpaId");
        vm.startPrank(_user);
        vm.expectRevert(SpotlightProtocolRewards.InvalidReturnData.selector);
        _protocolRewards.deposit{value: REWARD_AMOUNT}(nonIpaId);
        vm.stopPrank();
    }

    function testWithdrawSuccess() public {
        _enableWithdrawAndDeposit();
        assertEq(_user.balance, 0);
        assertEq(address(_protocolRewards).balance, REWARD_AMOUNT);

        uint256 tokenOwnerBalanceBefore = IPA_TOKEN_OWNER.balance;
        vm.startPrank(IPA_TOKEN_OWNER);

        vm.expectEmit(false, false, false, true);
        ISpotlightProtocolRewards.WithdrawInfo memory withdrawInfo =
            ISpotlightProtocolRewards.WithdrawInfo(IPA_TOKEN_CONTRACT, IPA_TOKEN_ID, REWARD_AMOUNT);
        emit ISpotlightProtocolRewards.Withdraw(withdrawInfo);

        _protocolRewards.withdraw(IPA_ID);

        assertEq(IPA_TOKEN_OWNER.balance, tokenOwnerBalanceBefore + REWARD_AMOUNT);
        assertEq(address(_protocolRewards).balance, 0);
        vm.stopPrank();
    }

    function testWithdrawRevertsWhenToAddressZero() public {
        _enableWithdrawAndDeposit();
        vm.startPrank(_user);
        vm.expectRevert(SpotlightProtocolRewards.AddressZero.selector);
        _protocolRewards.withdraw(address(0));
        vm.stopPrank();
    }

    function testWithdrawRevertsWhenRewardsZero() public {
        _enableWithdraw();

        vm.startPrank(IPA_TOKEN_OWNER);
        vm.expectRevert(SpotlightProtocolRewards.RewardsZero.selector);
        _protocolRewards.withdraw(IPA_ID);
        vm.stopPrank();
    }

    function testWithdrawRevertsWhenInvalidWithdraw() public {
        _enableWithdrawAndDeposit();

        vm.startPrank(_user);
        vm.expectRevert(SpotlightProtocolRewards.InvalidWithdraw.selector);
        _protocolRewards.withdraw(IPA_ID);
        vm.stopPrank();
    }

    function testWithdrawAllSuccess() public {
        _enableWithdrawAndDeposit();
        assertEq(_user.balance, 0);
        assertEq(address(_protocolRewards).balance, REWARD_AMOUNT);

        uint256 tokenOwnerBalanceBefore = IPA_TOKEN_OWNER.balance;
        vm.startPrank(IPA_TOKEN_OWNER);

        vm.expectEmit(false, false, false, true);
        ISpotlightProtocolRewards.WithdrawInfo[] memory withdrawInfos = new ISpotlightProtocolRewards.WithdrawInfo[](1);
        withdrawInfos[0] = ISpotlightProtocolRewards.WithdrawInfo(IPA_TOKEN_CONTRACT, IPA_TOKEN_ID, REWARD_AMOUNT);
        emit ISpotlightProtocolRewards.WithdrawAll(withdrawInfos);

        address[] memory ipaIds = new address[](1);
        ipaIds[0] = IPA_ID;
        _protocolRewards.withdrawAll(ipaIds);

        assertEq(IPA_TOKEN_OWNER.balance, tokenOwnerBalanceBefore + REWARD_AMOUNT);
        assertEq(address(_protocolRewards).balance, 0);
        vm.stopPrank();
    }

    function testWithdrawAllRevertsWhenIpaIdsEmpty() public {
        _enableWithdraw();
        address[] memory ipaIds = new address[](0);

        vm.startPrank(_user);
        vm.expectRevert(SpotlightProtocolRewards.IpaIdsEmpty.selector);
        _protocolRewards.withdrawAll(ipaIds);
        vm.stopPrank();
    }

    function testWithdrawAllRevertsWhenInvalidWithdraw() public {
        _enableWithdrawAndDeposit();

        address[] memory ipaIds = new address[](1);
        ipaIds[0] = IPA_ID;

        vm.startPrank(_user);
        vm.expectRevert(SpotlightProtocolRewards.InvalidWithdraw.selector);
        _protocolRewards.withdrawAll(ipaIds);
        vm.stopPrank();
    }

    function testWithdrawAllRevertsWhenRewardsZero() public {
        _enableWithdraw();

        address[] memory ipaIds = new address[](1);
        ipaIds[0] = IPA_ID;

        vm.startPrank(IPA_TOKEN_OWNER);
        vm.expectRevert(SpotlightProtocolRewards.RewardsZero.selector);
        _protocolRewards.withdrawAll(ipaIds);
        vm.stopPrank();
    }

    function testWithdrawAllRevertsWhenToAddressZero() public {
        _enableWithdrawAndDeposit();

        address[] memory ipaIds = new address[](1);
        ipaIds[0] = address(0);

        vm.startPrank(_user);
        vm.expectRevert(SpotlightProtocolRewards.AddressZero.selector);
        _protocolRewards.withdrawAll(ipaIds);
        vm.stopPrank();
    }

    function testTotalRewardsSuccess() public {
        _deposit();
        assertEq(_protocolRewards.totalRewards(), REWARD_AMOUNT);
    }

    function testRewardsOfSuccess() public {
        _deposit();
        assertEq(_protocolRewards.rewardsOf(IPA_ID), REWARD_AMOUNT);
        assertEq(_protocolRewards.rewardsOf(IPA_TOKEN_CONTRACT, IPA_TOKEN_ID), REWARD_AMOUNT);
    }

    function testRewardsOfRevertsWhenAddressZero() public {
        vm.expectRevert(SpotlightProtocolRewards.AddressZero.selector);
        _protocolRewards.rewardsOf(address(0));

        vm.expectRevert(SpotlightProtocolRewards.AddressZero.selector);
        _protocolRewards.rewardsOf(address(0), 0);
    }

    function _enableWithdraw() internal {
        vm.prank(_owner);
        _protocolRewards.setWithdrawEnabled(true);
    }

    function _deposit() internal {
        vm.prank(_user);
        _protocolRewards.deposit{value: REWARD_AMOUNT}(IPA_ID);
    }

    function _enableWithdrawAndDeposit() internal {
        _enableWithdraw();
        _deposit();
    }
}
