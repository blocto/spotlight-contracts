// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {SpotlightTokenFactory} from "../src/spotlight-token-factory/SpotlightTokenFactory.sol";
import {SpotlightTokenIPCollection} from "../src/spotlight-token-collection/SpotlightTokenIPCollection.sol";
import {SpotlightNativeBondingCurve} from "../src/spotlight-bonding-curve/SpotlightNativeBondingCurve.sol";
import {SpotlightToken} from "../src/spotlight-token/SpotlightToken.sol";
import {SpotlightRewardsVault} from "../src/spotlight-rewards-vault/SpotlightRewardsVault.sol";

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

    address private _STORY_DERIVATIVE_WORKFLOWS_ADDRESS = 0x9e2d496f72C547C2C535B167e06ED8729B374a4f;
    address private _SPOTLIGHT_TOKEN_FACTORY_OWNER = 0x0FbAd0dd681679112F8D1635d2C07C93dBd294B1;

    address private constant PIPERX_V2_ROUTER = 0x674eFAa8C50cBEF923ECe625d3c276B7Bb1c16fB;
    address private constant PIPERX_V2_FACTORY = 0x6D3e2f58954bf4E1d0C4bA26a85a1b49b2e244C6;

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // @dev deploy spotlight token ip collection contract
        SpotlightTokenIPCollection tokenIpCollection = new SpotlightTokenIPCollection(
            address(0) // token factory address, will be  set later
        );

        // @dev deploy spotlight bonding curve contract
        SpotlightNativeBondingCurve bondingCurve = new SpotlightNativeBondingCurve(
            840_000_000_000, // A=8.4×10^−7
            3_500_000_000 // B=3.5×10^−9
        );

        // @dev deploy spotlight token implementation contract
        SpotlightToken spotlightTokenImpl = new SpotlightToken();

        // @dev deploy spotlight token factory implementation contract
        SpotlightTokenFactory factoryImpl = new SpotlightTokenFactory();

        // @dev deploy spotlight protocol rewards contract
        SpotlightRewardsVault rewardsVault = new SpotlightRewardsVault();

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
            address(rewardsVault) // rewardsVault_
        );
        tokenIpCollection.setTokenFactory(address(factoryProxy));
        vm.stopBroadcast();
    }
}
