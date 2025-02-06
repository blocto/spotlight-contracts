// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {SpotlightTokenFactory} from "../src/spotlight-token-factory/SpotlightTokenFactory.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract Upgrade is Script {
    address private constant currentTokenFactoryProxyAddress = 0x95fc331fD93644aDCa07dB9280f7bb1Fde8D1515;
    address private constant proxyAdminAddress = 0x8664B88d7cEc53217725867981b04aDB26A728C7;

    function run() public {
        vm.startBroadcast();

        SpotlightTokenFactory newTokenFactoryImpl = new SpotlightTokenFactory();

        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);
        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(currentTokenFactoryProxyAddress), address(newTokenFactoryImpl), ""
        );

        vm.stopBroadcast();
    }
}
