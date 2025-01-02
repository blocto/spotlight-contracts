// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {MarketType} from "./ISpotlightToken.sol";

abstract contract SpotlightTokenStorage {
    // @dev v1 properties
    uint256 public constant BONDING_CURVE_SUPPLY = 800_000_000e18; // 0.8 billion
    uint256 public constant PROTOCOL_TRADING_FEE_PCT = 1; // 100%
    uint256 public constant MIN_IP_ORDER_SIZE = 0.5 ether; // 0.5 IP

    address internal _owner;
    address internal _tokenCreator;
    address internal _protocolFeeRecipient;
    address internal _bondingCurve;
    address internal _baseToken;
    bool internal _isInitialized;
    // @dev end of v1 properties

    // @dev v2 properties - trading on dex
    uint256 public constant MAX_TOTAL_SUPPLY = 1_000_000_000e18; // 1 billion
    uint256 public constant SECONDARY_MARKET_SUPPLY = 200_000_000e18; // 0.2 billion
    uint256 public constant TOTAL_FEE_BPS = 1; // 1%

    address internal _piperXRouter;
    address internal _piperXFactory;
    address internal _pairAddress;
    MarketType internal _marketType;
    // @dev end of v2 properties
}
