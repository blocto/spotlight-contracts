// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import {SpotlightRewardsVault} from "../src/spotlight-rewards-vault/SpotlightRewardsVault.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISpotlightRewardsVault} from "../src/spotlight-rewards-vault/ISpotlightRewardsVault.sol";

contract SpotlightRewardsVaultTest is Test {
    address constant IPA_ID = 0x9ea65c24f87F6F196B435F65103204A463bcFF17;
    address constant IPA_TOKEN_CONTRACT = 0xFFcCD25f12Bcb322816B099C6A0087cc7De711Bc;
    uint256 constant IPA_TOKEN_ID = 0;
    address constant IPA_TOKEN_OWNER = 0x0FbAd0dd681679112F8D1635d2C07C93dBd294B1;

    uint256 constant DEFAULT_BALANCE = 1 ether;
    uint256 constant REWARD_AMOUNT = 1 ether;

    address private _user;
    address private _owner;
    SpotlightRewardsVault private _rewardsVault;

    function setUp() public {
        _user = makeAddr("user");
        vm.deal(_user, DEFAULT_BALANCE);
        _owner = makeAddr("owner");
        vm.deal(_owner, DEFAULT_BALANCE);
        vm.prank(_owner);
        _rewardsVault = new SpotlightRewardsVault();
    }

    function testOwnerIsDeployer() public view {
        assertEq(_rewardsVault.owner(), _owner);
    }

    function testIsWithdrawEnabledDefaultReturnsFalse() public view {
        bool isEnabled = _rewardsVault.isWithdrawEnabled();
        assertFalse(isEnabled);
    }

    function testSetWithdrawEnabledSuccessWithOwner() public {
        vm.prank(_owner);
        _rewardsVault.setWithdrawEnabled(true);
        assertTrue(_rewardsVault.isWithdrawEnabled());
    }

    function testSetWithdrawEnabledRevertsWhenNotOwner() public {
        address nonOwner = makeAddr("nonOwner");
        vm.prank(nonOwner);
        vm.expectRevert();
        _rewardsVault.setWithdrawEnabled(true);
    }

    function testDepositSuccess() public {
        vm.startPrank(_user);
        vm.expectEmit(false, false, false, true);
        emit ISpotlightRewardsVault.Deposit(IPA_TOKEN_CONTRACT, IPA_TOKEN_ID, REWARD_AMOUNT);
        _rewardsVault.deposit{value: REWARD_AMOUNT}(IPA_ID);
        vm.stopPrank();
    }

    function testDepositRevertsWhenToAddressZero() public {
        vm.startPrank(_user);
        vm.expectRevert(SpotlightRewardsVault.AddressZero.selector);
        _rewardsVault.deposit{value: REWARD_AMOUNT}(address(0));
        vm.stopPrank();
    }

    function testDepositRevertsWhenAmountZero() public {
        vm.startPrank(_user);
        vm.expectRevert(SpotlightRewardsVault.AmountZero.selector);
        _rewardsVault.deposit{value: 0}(IPA_ID);
        vm.stopPrank();
    }

    function testWithdrawSuccess() public {
        _enableWithdrawAndDeposit();
        assertEq(_user.balance, 0);
        assertEq(address(_rewardsVault).balance, REWARD_AMOUNT);

        uint256 tokenOwnerBalanceBefore = IPA_TOKEN_OWNER.balance;
        vm.startPrank(IPA_TOKEN_OWNER);

        vm.expectEmit(false, false, false, true);
        ISpotlightRewardsVault.WithdrawInfo memory withdrawInfo =
            ISpotlightRewardsVault.WithdrawInfo(IPA_TOKEN_CONTRACT, IPA_TOKEN_ID, REWARD_AMOUNT);
        emit ISpotlightRewardsVault.Withdraw(withdrawInfo);

        _rewardsVault.withdraw(IPA_ID);

        assertEq(IPA_TOKEN_OWNER.balance, tokenOwnerBalanceBefore + REWARD_AMOUNT);
        assertEq(address(_rewardsVault).balance, 0);
        vm.stopPrank();
    }

    function testWithdrawRevertsWhenToAddressZero() public {
        _enableWithdrawAndDeposit();
        vm.startPrank(_user);
        vm.expectRevert(SpotlightRewardsVault.AddressZero.selector);
        _rewardsVault.withdraw(address(0));
        vm.stopPrank();
    }

    function testWithdrawRevertsWhenRewardsZero() public {
        _enableWithdraw();

        vm.startPrank(IPA_TOKEN_OWNER);
        vm.expectRevert(SpotlightRewardsVault.RewardsZero.selector);
        _rewardsVault.withdraw(IPA_ID);
        vm.stopPrank();
    }

    function testWithdrawRevertsWhenInvalidWithdraw() public {
        _enableWithdrawAndDeposit();

        vm.startPrank(_user);
        vm.expectRevert(SpotlightRewardsVault.InvalidWithdraw.selector);
        _rewardsVault.withdraw(IPA_ID);
        vm.stopPrank();
    }

    function testWithdrawAllSuccess() public {
        _enableWithdrawAndDeposit();
        assertEq(_user.balance, 0);
        assertEq(address(_rewardsVault).balance, REWARD_AMOUNT);

        uint256 tokenOwnerBalanceBefore = IPA_TOKEN_OWNER.balance;
        vm.startPrank(IPA_TOKEN_OWNER);

        vm.expectEmit(false, false, false, true);
        ISpotlightRewardsVault.WithdrawInfo[] memory withdrawInfos = new ISpotlightRewardsVault.WithdrawInfo[](1);
        withdrawInfos[0] = ISpotlightRewardsVault.WithdrawInfo(IPA_TOKEN_CONTRACT, IPA_TOKEN_ID, REWARD_AMOUNT);
        emit ISpotlightRewardsVault.WithdrawAll(withdrawInfos);

        address[] memory ipaIds = new address[](1);
        ipaIds[0] = IPA_ID;
        _rewardsVault.withdrawAll(ipaIds);

        assertEq(IPA_TOKEN_OWNER.balance, tokenOwnerBalanceBefore + REWARD_AMOUNT);
        assertEq(address(_rewardsVault).balance, 0);
        vm.stopPrank();
    }

    function testWithdrawAllRevertsWhenIpaIdsEmpty() public {
        _enableWithdraw();
        address[] memory ipaIds = new address[](0);

        vm.startPrank(_user);
        vm.expectRevert(SpotlightRewardsVault.IPAccountsEmpty.selector);
        _rewardsVault.withdrawAll(ipaIds);
        vm.stopPrank();
    }

    function testWithdrawAllRevertsWhenInvalidWithdraw() public {
        _enableWithdrawAndDeposit();

        address[] memory ipaIds = new address[](1);
        ipaIds[0] = IPA_ID;

        vm.startPrank(_user);
        vm.expectRevert(SpotlightRewardsVault.InvalidWithdraw.selector);
        _rewardsVault.withdrawAll(ipaIds);
        vm.stopPrank();
    }

    function testWithdrawAllRevertsWhenRewardsZero() public {
        _enableWithdraw();

        address[] memory ipaIds = new address[](1);
        ipaIds[0] = IPA_ID;

        vm.startPrank(IPA_TOKEN_OWNER);
        vm.expectRevert(SpotlightRewardsVault.RewardsZero.selector);
        _rewardsVault.withdrawAll(ipaIds);
        vm.stopPrank();
    }

    function testWithdrawAllRevertsWhenToAddressZero() public {
        _enableWithdrawAndDeposit();

        address[] memory ipaIds = new address[](1);
        ipaIds[0] = address(0);

        vm.startPrank(_user);
        vm.expectRevert(SpotlightRewardsVault.AddressZero.selector);
        _rewardsVault.withdrawAll(ipaIds);
        vm.stopPrank();
    }

    function testTotalRewardsSuccess() public {
        _deposit();
        assertEq(_rewardsVault.totalRewards(), REWARD_AMOUNT);
    }

    function testRewardsOfSuccess() public {
        _deposit();
        assertEq(_rewardsVault.rewardsOf(IPA_ID), REWARD_AMOUNT);
        assertEq(_rewardsVault.rewardsOf(IPA_TOKEN_CONTRACT, IPA_TOKEN_ID), REWARD_AMOUNT);
    }

    function testRewardsOfRevertsWhenAddressZero() public {
        vm.expectRevert(SpotlightRewardsVault.AddressZero.selector);
        _rewardsVault.rewardsOf(address(0));

        vm.expectRevert(SpotlightRewardsVault.AddressZero.selector);
        _rewardsVault.rewardsOf(address(0), 0);
    }

    function _enableWithdraw() internal {
        vm.prank(_owner);
        _rewardsVault.setWithdrawEnabled(true);
    }

    function _deposit() internal {
        vm.prank(_user);
        _rewardsVault.deposit{value: REWARD_AMOUNT}(IPA_ID);
    }

    function _enableWithdrawAndDeposit() internal {
        _enableWithdraw();
        _deposit();
    }
}
