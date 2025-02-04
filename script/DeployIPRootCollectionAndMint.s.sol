// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {SpotlightRootIPCollection} from "../src/spotlight-root-ip-collection/SpotlightRootIPCollection.sol";

contract Deploy is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        SpotlightRootIPCollection ipCollection = new SpotlightRootIPCollection();
        ipCollection.mint();
        vm.stopBroadcast();
    }
}
