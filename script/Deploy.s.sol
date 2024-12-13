// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {SpotlightTokenFaucet} from "../src/spotlight-token-faucet/SpotlightTokenFaucet.sol";
import {SpotlightTokenFactory} from "../src/spotlight-token-factory/SpotlightTokenFactory.sol";
import {SpotlightTokenIPCollection} from "../src/spotlight-token-collection/SpotlightTokenIPCollection.sol";
import {SpotlightUSDCBondingCurve} from "../src/spotlight-bonding-curve/SpotlightUSDCBondingCurve.sol";

contract Deploy is Script {
    /**
     * @dev Odyssey chain id: 1516
     * @dev Odyssey rpc: https://odyssey.storyrpc.io
     */

    /* Deploy and verify with the following command:
        forge script script/Deploy.s.sol:Deploy  --broadcast \
        --chain-id 1516 \
        --rpc-url https://odyssey.storyrpc.io \
        --verify \
        --verifier blockscout \
        --verifier-url 'https://odyssey.storyscan.xyz/api/' 
    */

    //@notice The address of the SUSDCToken contract on Odyssey.(https://odyssey.storyscan.xyz/address/0x40fCa9cB1AB15eD9B5bDA19A52ac00A78AE08e1D?tab=contract)
    address private _SUSDCTokenAddr = 0x40fCa9cB1AB15eD9B5bDA19A52ac00A78AE08e1D;
    address private _STORY_DERIVATIVE_WORKFLOWS_ADDRESS = 0xa8815CEB96857FFb8f5F8ce920b1Ae6D70254C7B;

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        // new SpotlightTokenFaucet(_SUSDCTokenAddr);
        // SpotlightTokenFactory factory = new SpotlightTokenFactory(0, address(0), _STORY_DERIVATIVE_WORKFLOWS_ADDRESS);
        // SpotlightTokenIPCollection tokenIpCollection = new SpotlightTokenIPCollection(address(factory));
        // factory.setTokenIpCollection(address(tokenIpCollection));

        new SpotlightUSDCBondingCurve(
            6_900_000_000_000, // A=6.9*10^-6
            2_878_200_000 // B=2.8782×10^−9
        );
        vm.stopBroadcast();
    }
}
