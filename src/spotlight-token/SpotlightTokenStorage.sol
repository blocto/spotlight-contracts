// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {MarketType} from "./ISpotlightToken.sol";

abstract contract SpotlightTokenStorage {
    uint256 public constant BONDING_CURVE_SUPPLY = 800_000_000e18; // 0.8 billion
    uint256 public constant SECONDARY_MARKET_SUPPLY = 200_000_000e18; // 0.2 billion
    uint256 public constant MAX_TOTAL_SUPPLY = BONDING_CURVE_SUPPLY + SECONDARY_MARKET_SUPPLY; // 1 billion

    uint256 public constant TOTAL_FEE_BPS = 100; // 1%
    uint256 public constant IP_ACCOUNT_FEE_BPS = 1_000; // 10% to IPAccount, 90% to protocol
    uint256 public constant LISTING_FEE = 0.1 ether;

    uint256 public constant MIN_IP_ORDER_SIZE = 0.0001 ether; // 0.0001 IP

    address internal _tokenCreator;
    address internal _bondingCurve;
    address internal _protocolFeeRecipient;
    address internal _ipAccount;
    address internal _rewardsVault;
    address internal _piperXRouter;
    address internal _piperXFactory;

    MarketType internal _marketType;
    address internal _pairAddress;
}
