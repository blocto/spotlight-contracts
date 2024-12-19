// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {BeaconProxyStorage} from "../beacon-proxy/BeaconProxyStorage.sol";

interface IBeacon {
    function implementation() external view returns (address);
}

abstract contract Proxy {
    struct AddressSlot {
        address value;
    }

    function _delegate(address implementation) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    function _implementation() internal view virtual returns (address);

    function _fallback() internal virtual {
        _delegate(_implementation());
    }

    fallback() external payable virtual {
        _fallback();
    }
}

contract BeaconProxy is BeaconProxyStorage, Proxy {
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(address beacon) payable {
        _setImplementation(beacon);
        _beacon = beacon;
    }

    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    function _getBeacon() internal view virtual returns (address) {
        return _beacon;
    }

    function _setImplementation(address newImplementation) private {
        if (newImplementation.code.length == 0) {
            revert("");
        }
        getAddressSlot(IMPLEMENTATION_SLOT).value = newImplementation;
    }

    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }
}
