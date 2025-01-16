// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

abstract contract SpotlightTokenFactoryStorage {
    // @dev v1 properties
    address internal _owner;
    uint256 internal _creationFee;
    address internal _creationFeeToken; //deprecated
    address internal _tokenBeacon;
    address internal _bondingCurve;
    address internal _baseToken;
    address internal _tokenIpCollection;
    address internal _storyDerivativeWorkflows;
    mapping(address => uint256) internal _numbersOfTokensCreated;

    bool internal _isInitialized;
    // @dev end of v1 properties
    // @dev v2 properties
    address internal _piperXRouter;
    address internal _piperXFactory;
    address internal _protocolRewards;
    // @dev end of v2 properties
}
