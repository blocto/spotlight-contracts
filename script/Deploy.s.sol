// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {SpotlightTokenFaucet} from "../src/spotlight-token-faucet/SpotlightTokenFaucet.sol";

contract Deploy is Script {
    /**
     * @dev Odyssey chain id: 1516
     * @dev Odyssey rpc: https://odyssey.storyrpc.io
     */

    /* Deploy with the following command:
        forge script script/Deploy.s.sol:Deploy  --broadcast \
        --chain-id 1516 \
        --rpc-url https://odyssey.storyrpc.io \
    */

    //@notice The address of the SUSDCToken contract on Odyssey.(https://odyssey.storyscan.xyz/address/0x40fCa9cB1AB15eD9B5bDA19A52ac00A78AE08e1D?tab=contract)
    address private _SUSDCTokenAddr =
        0x40fCa9cB1AB15eD9B5bDA19A52ac00A78AE08e1D;

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        new SpotlightTokenFaucet(_SUSDCTokenAddr);
        vm.stopBroadcast();
    }
}
