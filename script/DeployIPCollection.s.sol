// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {SpotlightIPCollection} from "../src/spotlight-ip-collection/SpotlightIPCollection.sol";

/* Deploy and verify with the following command:
    forge script script/DeployIPCollection.s.sol:Deploy --broadcast \
      --chain-id 1516 \
      --rpc-url https://odyssey.storyrpc.io \
      --verify \
      --verifier blockscout \
      --verifier-url 'https://odyssey.storyscan.xyz/api/' 
*/

contract Deploy is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        SpotlightIPCollection ipCollection = new SpotlightIPCollection();
        ipCollection.setDefaultTokenURI("ipfs://bafkreifsq7jdvvlj7cabklirodim7syc5xt4yzbrny6i4siie4yrnnqzge");
        vm.stopBroadcast();
    }
}
