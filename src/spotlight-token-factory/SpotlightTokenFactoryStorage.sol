// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

abstract contract SpotlightTokenFactoryStorage {
    uint256 internal _creationFee;
    address internal _tokenIpCollection;
    address internal _tokenImplementation;
    address internal _bondingCurve;
    address internal _storyDerivativeWorkflows;
    address internal _piperXRouter;
    address internal _piperXFactory;
    address internal _rewardsVault;

    mapping(address => uint256) internal _numbersOfTokensCreated;
}
