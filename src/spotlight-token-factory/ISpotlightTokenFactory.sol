// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface ISpotlightTokenFactory {
    /**
     * @dev Returns the address of the token collection contract
     */
    function tokenCollection() external view returns (address);

    /**
     */
    function calculateTokenAddress(address tokenCreator, string memory tokenName, string memory tokenSymbol)
        external
        returns (address);
}
