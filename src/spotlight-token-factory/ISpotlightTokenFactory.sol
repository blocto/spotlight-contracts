// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface ISpotlightTokenFactory {
    function calculateTokenAddress(address tokenCreator, string memory tokenName, string memory tokenSymbol)
        external
        returns (address);
}
