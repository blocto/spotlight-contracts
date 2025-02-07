// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {SpotlightTokenFactory} from "../src/spotlight-token-factory/SpotlightTokenFactory.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract Claim is Script {
    address private constant tokenFactoryProxyAddress = 0x95fc331fD93644aDCa07dB9280f7bb1Fde8D1515;

    function run() public {
        vm.startBroadcast();
        SpotlightTokenFactory tokenFactory = SpotlightTokenFactory(payable(address(tokenFactoryProxyAddress)));
        tokenFactory.claimFee(0x0FbAd0dd681679112F8D1635d2C07C93dBd294B1);
        vm.stopBroadcast();
    }
}
