// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {SpotlightTokenFactory} from "../src/spotlight-token-factory/SpotlightTokenFactory.sol";
import {SpotlightTokenIPCollection} from "../src/spotlight-token-collection/SpotlightTokenIPCollection.sol";
import {SpotlightNativeBondingCurve} from "../src/spotlight-bonding-curve/SpotlightNativeBondingCurve.sol";
import {SpotlightToken} from "../src/spotlight-token/SpotlightToken.sol";
import {SpotlightProtocolRewards} from "../src/spotlight-protocol-rewards/SpotlightProtocolRewards.sol";

contract Deploy is Script {
    /**
     * @dev Odyssey chain id: 1516
     * @dev Odyssey rpc: https://odyssey.storyrpc.io
     */

    /* Deploy and verify with the following command:
        forge script script/DeployTokenFactory.s.sol:Deploy  --broadcast \
        --chain-id 1516 \
        --rpc-url https://odyssey.storyrpc.io \
        --verify \
        --verifier blockscout \
        --verifier-url 'https://odyssey.storyscan.xyz/api/' 
    */

    /**
     * @dev Odyssey chain id: 1516
     * @dev Odyssey rpc: https://odyssey.storyrpc.io
     */

    /* verify contract with the following command:
    forge verify-contract \
        --rpc-url https://odyssey.storyrpc.io \
        --verifier blockscout \
        --verifier-url 'https://odyssey.storyscan.xyz/api/' \
        {REPLACE_CONTRACT_ADDRESS} \
        src/{CONTRACT_PATH}.sol:{CONTRACT_NAME}
    */

    address private _STORY_DERIVATIVE_WORKFLOWS_ADDRESS = 0xa8815CEB96857FFb8f5F8ce920b1Ae6D70254C7B;
    address private _SPOTLIGHT_TOKEN_FACTORY_OWNER = 0x582d6944a8EA7e4ACD385D18DC95CF5915510289;

    address private constant PIPERX_V2_ROUTER = 0x8812d810EA7CC4e1c3FB45cef19D6a7ECBf2D85D;
    address private constant PIPERX_V2_FACTORY = 0x700722D24f9256Be288f56449E8AB1D27C4a70ca;

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // @dev deploy spotlight token ip collection contract
        SpotlightTokenIPCollection tokenIpCollection = new SpotlightTokenIPCollection(
            address(0) // token factory address, will be  set later
        );

        // @dev deploy spotlight bonding curve contract
        SpotlightNativeBondingCurve bondingCurve = new SpotlightNativeBondingCurve(
            690_000_000, // A=6.9*10^-6
            2_878_200_000 // B=2.8782×10^−9
        );

        // @dev deploy spotlight token implementation contract
        SpotlightToken spotlightTokenImpl = new SpotlightToken();

        // @dev deploy spotlight token factory implementation contract
        SpotlightTokenFactory factoryImpl = new SpotlightTokenFactory();

        // @dev deploy spotlight protocol rewards contract
        SpotlightProtocolRewards protocolRewards = new SpotlightProtocolRewards();

        // @dev deploy spotlight token factory proxy contract
        TransparentUpgradeableProxy factoryProxy =
            new TransparentUpgradeableProxy(address(factoryImpl), _SPOTLIGHT_TOKEN_FACTORY_OWNER, "");
        SpotlightTokenFactory(payable(address(factoryProxy))).initialize(
            _SPOTLIGHT_TOKEN_FACTORY_OWNER, // owner_
            0.1 ether, // creationFee: 0.1 ether
            address(tokenIpCollection), // tokenIpCollection_
            address(spotlightTokenImpl), // tokenImplementation_
            address(bondingCurve), // bondingCurve_
            _STORY_DERIVATIVE_WORKFLOWS_ADDRESS, // storyDerivativeWorkflows_
            PIPERX_V2_ROUTER, // piperxV2Router_
            PIPERX_V2_FACTORY, // piperxV2Factory_
            address(protocolRewards) // protocolRewards_
        );
        tokenIpCollection.setTokenFactory(address(factoryProxy));
        tokenIpCollection.setMintEnabled(true);
        vm.stopBroadcast();
    }
}
