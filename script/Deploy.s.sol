// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {SpotlightTokenFaucet} from "../src/spotlight-token-faucet/SpotlightTokenFaucet.sol";
import {SpotlightTokenFactory} from "../src/spotlight-token-factory/SpotlightTokenFactory.sol";
import {SpotlightTokenIPCollection} from "../src/spotlight-token-collection/SpotlightTokenIPCollection.sol";
import {SpotlightUSDCBondingCurve} from "../src/spotlight-bonding-curve/SpotlightUSDCBondingCurve.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {SpotlightToken} from "../src/spotlight-token/SpotlightToken.sol";
import {BeaconProxy} from "../src/beacon-proxy/BeaconProxy.sol";

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

    address private _SPOTLIGHT_TOKEN_FACTORY_OWNER = 0x582d6944a8EA7e4ACD385D18DC95CF5915510289;

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        // new SpotlightTokenFaucet(_SUSDCTokenAddr);
        // SpotlightTokenFactory factory = new SpotlightTokenFactory(0, address(0), _STORY_DERIVATIVE_WORKFLOWS_ADDRESS);
        // SpotlightTokenIPCollection tokenIpCollection = new SpotlightTokenIPCollection(address(factory));
        // factory.setTokenIpCollection(address(tokenIpCollection));

        // new SpotlightUSDCBondingCurve(
        //     6_900_000_000_000, // A=6.9*10^-6
        //     2_878_200_000 // B=2.8782×10^−9
        // );

        // @dev deploy spotlight token implementation contract
        // SpotlightToken spotlightTokenImpl = new SpotlightToken();

        // @dev deploy spotlight token beacon contract
        // UpgradeableBeacon spotlightTokenBeacon = new UpgradeableBeacon(
        //     address(spotlightTokenImpl),
        //     _SPOTLIGHT_TOKEN_FACTORY_OWNER
        // );

        // @dev deploy spotlight token factory implementation contract
        // SpotlightTokenFactory factoryImpl = new SpotlightTokenFactory(
        //     5_000_000, // creationFee: 5 usdc
        //     _SUSDCTokenAddr, // creationFeeToken_
        //     0xf23BF6DCbdf83De455d39b50ee2a9B7cFC5a4AB0, // tokenBeacon_
        //     0x2D6f361616a6eF15305d0099434D854f98E5cFE9, // bondingCurve_
        //     _SUSDCTokenAddr, // baseToken_
        //     _STORY_DERIVATIVE_WORKFLOWS_ADDRESS // storyDerivativeWorkflows_
        // );

        // @dev deploy spotlight token factory beacon contract
        // UpgradeableBeacon spotlightTokenBeacon = new UpgradeableBeacon(
        //     0x043a1D75f6A7ACe220f3E852637422d38b39288D,
        //     _SPOTLIGHT_TOKEN_FACTORY_OWNER
        // );

        // @dev deploy spotlight token factory proxy contract
        BeaconProxy beaconProxy = new BeaconProxy(0x0e080cF41caEd4C3d29404798AbDca1c1c34b4f3);
        vm.stopBroadcast();
    }
}
