// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {SpotlightTokenFaucet} from "./SpotlightTokenFaucet.sol";

contract SpotlightUSDCFaucet is SpotlightTokenFaucet {
    constructor() SpotlightTokenFaucet("Spotlight USDC", "SUSDC") {}
}
