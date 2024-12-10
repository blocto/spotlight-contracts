// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import {SpotlightTokenFactory} from "../src/spotlight-token-factory/SpotlightTokenFactory.sol";
import {SpotlightToken} from "../src/spotlight-token/SpotlightToken.sol";

contract SpotlightTokenFactoryTest is Test {
    address private _factoryOwner;

    SpotlightTokenFactory private _factory;
    address private _factoryAddress;

    function setUp() public {
        _factoryOwner = makeAddr("factoryOwner");

        vm.startPrank(_factoryOwner);
        _factory = new SpotlightTokenFactory();
        _factoryAddress = address(_factory);
        vm.stopPrank();
    }

    function testCreateTokneAddress() public {
        address tokenCreator = makeAddr("tokenCreator");
        uint256 numberOfTokensCreatedBefore = _factory.numberOfTokensCreated(tokenCreator);

        string memory tokenName = "Test Token";
        string memory tokenSymbol = "TT";

        address calculatedAddr = _factory.calculateTokenAddress(tokenCreator, tokenName, tokenSymbol);

        vm.startPrank(tokenCreator);
        address tokenAddr = _factory.createToken(tokenName, tokenSymbol, calculatedAddr);
        vm.stopPrank();

        assertEq(_factory.numberOfTokensCreated(tokenCreator), numberOfTokensCreatedBefore + 1);
    }
}
