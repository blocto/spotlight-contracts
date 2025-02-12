// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {SpotlightTokenFactory} from "../src/spotlight-token-factory/SpotlightTokenFactory.sol";
import {SpotlightToken} from "../src/spotlight-token/SpotlightToken.sol";

contract SetNewTokenImplementationScript is Script {
    address private constant currentTokenFactoryProxyAddress = 0x33e5779E8526200A107B8C4B5893E0875c0F15A6;

    function run() public {
        vm.startBroadcast();

        // @dev deploy spotlight token implementation contract
        SpotlightToken spotlightTokenImpl = new SpotlightToken();

        // @dev set new token implementation
        SpotlightTokenFactory(payable(currentTokenFactoryProxyAddress)).setTokenImplementation(
            address(spotlightTokenImpl)
        );

        vm.stopBroadcast();
    }
}
