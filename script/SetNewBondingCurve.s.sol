// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {SpotlightTokenFactory} from "../src/spotlight-token-factory/SpotlightTokenFactory.sol";
import {SpotlightToken} from "../src/spotlight-token/SpotlightToken.sol";
import {SpotlightNativeBondingCurve} from "../src/spotlight-bonding-curve/SpotlightNativeBondingCurve.sol";

contract SetNewBondingCurveScript is Script {
    address private constant currentTokenFactoryProxyAddress = 0xBc74Ef58EeB9644168E953cD426998E660C323A4;

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // @dev deploy spotlight bonding curve contract
        SpotlightNativeBondingCurve bondingCurve = new SpotlightNativeBondingCurve(
            700_000_000_000, // A = 7×10^−7
            3_500_000_000 // B = 3.5×10^−9
        );

        // @dev set new token implementation
        SpotlightTokenFactory(payable(currentTokenFactoryProxyAddress)).setBondingCurve(address(bondingCurve));

        vm.stopBroadcast();
    }
}
