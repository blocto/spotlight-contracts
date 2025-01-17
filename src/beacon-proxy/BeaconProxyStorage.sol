// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

/*
 * @dev to algin the storage slots with the proxy contract
 */
abstract contract BeaconProxyStorage {
    address internal immutable _beacon;
}
