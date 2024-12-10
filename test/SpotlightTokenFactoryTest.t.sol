// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import {SpotlightToken} from "../src/spotlight-token/SpotlightToken.sol";
import {SpotlightTokenCollection} from "../src/spotlight-token-collection/SpotlightTokenCollection.sol";
import {SpotlightTokenFactory} from "../src/spotlight-token-factory/SpotlightTokenFactory.sol";

contract SpotlightTokenFactoryTest is Test {
    address private _factoryOwner;

    SpotlightTokenFactory private _factory;
    address private _factoryAddress;

    SpotlightTokenCollection private _tokenCollection;
    address private _tokenCollectionAddress;

    function setUp() public {
        _factoryOwner = makeAddr("factoryOwner");

        vm.startPrank(_factoryOwner);
        _factory = new SpotlightTokenFactory(0, address(0));
        _factoryAddress = address(_factory);
        vm.stopPrank();

        _tokenCollectionAddress = _factory.tokenCollection();
        _tokenCollection = SpotlightTokenCollection(_tokenCollectionAddress);

        vm.startPrank(_factoryOwner);
        _tokenCollection.setMintEnabled(true);
        vm.stopPrank();
    }

    function testCreateToken() public {
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
