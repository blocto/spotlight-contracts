// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {SpotlightRootIPCollection} from "../src/spotlight-root-ip-collection/SpotlightRootIPCollection.sol";

/* Deploy and verify with the following command:
    forge script script/DeployIPRootCollectionAndMint.s.sol:Deploy --broadcast \
      --chain-id 1516 \
      --rpc-url https://odyssey.storyrpc.io \
      --verify \
      --verifier blockscout \
      --verifier-url 'https://odyssey.storyscan.xyz/api/' 
*/

contract Deploy is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        SpotlightRootIPCollection ipCollection = new SpotlightRootIPCollection();
        ipCollection.mint();
        vm.stopBroadcast();
    }
}
