// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

abstract contract SpotlightTokenStorage {
    // @dev v1 properties
    uint256 public constant BONDIGN_CURVE_SUPPLY = 800_000_000e18; // 0.8 billion
    uint256 public constant PROTOCOL_TRADING_FEE_PCT = 1; // 1%
    uint256 public constant MIN_USDC_ORDER_SIZE = 100; // 0.0001 USDC

    address internal _owner;
    address internal _tokenCreator;
    address internal _protocolFeeRecipient;
    address internal _bondingCurve;
    address internal _baseToken;
    bool internal _isInitialized;
    // @dev end of v1 properties
}
