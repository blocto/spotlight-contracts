// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import {SpotlightToken} from "../src/spotlight-token/SpotlightToken.sol";
import {SpotlightTokenIPCollection} from "../src/spotlight-token-collection/SpotlightTokenIPCollection.sol";
import {SpotlightTokenFactory} from "../src/spotlight-token-factory/SpotlightTokenFactory.sol";

contract SpotlightTokenFactoryTest is Test {
    address private _factoryOwner;
    address private STORY_DERIVATIVE_WORKFLOWS_ADDRESS = 0xa8815CEB96857FFb8f5F8ce920b1Ae6D70254C7B;
    uint256 private DEFAULT_CREATION_FEE = 0;
    address private DEFAULT_CREATION_FEE_TOKEN = makeAddr("defaultCreationFeeToken");

    SpotlightTokenFactory private _factory;
    address private _factoryAddress;

    function setUp() public {
        _factoryOwner = makeAddr("factoryOwner");
        vm.startPrank(_factoryOwner);
        _factory = new SpotlightTokenFactory();
        _factoryAddress = address(_factory);
        _factory.initialize(
            DEFAULT_CREATION_FEE,
            DEFAULT_CREATION_FEE_TOKEN,
            makeAddr("tokenBeacon"),
            makeAddr("bondingCurve"),
            makeAddr("baseToken"),
            STORY_DERIVATIVE_WORKFLOWS_ADDRESS
        );
        vm.stopPrank();
    }

    function testTokenFactoryConstructor() public view {
        assertEq(_factory.owner(), _factoryOwner);
        assertEq(_factory.createTokenFee(), DEFAULT_CREATION_FEE);
        assertEq(_factory.feeToken(), DEFAULT_CREATION_FEE_TOKEN);
        assertEq(_factory.storyDerivativeWorkflows(), STORY_DERIVATIVE_WORKFLOWS_ADDRESS);
    }

    function testNotOwnerSetTokenIpCollection() public {
        address notOwner = makeAddr("notOwner");

        vm.startPrank(notOwner);
        vm.expectRevert();
        _factory.setTokenIpCollection(makeAddr("newTokenIpCollection"));
        vm.stopPrank();
    }

    function testSetTokneIpCollection() public {
        vm.startPrank(_factoryOwner);
        SpotlightTokenIPCollection tokenIpCollection = new SpotlightTokenIPCollection(_factoryAddress);
        address tokenIpCollectionAddress = address(tokenIpCollection);
        _factory.setTokenIpCollection(tokenIpCollectionAddress);
        vm.stopPrank();
        assertEq(_factory.tokenIpCollection(), tokenIpCollectionAddress);
        assertEq(tokenIpCollection.owner(), _factoryOwner);
        assertEq(tokenIpCollection.tokenFactory(), _factoryAddress);
    }

    function testNotOwnerSetCreationFee() public {
        address notOwner = makeAddr("notOwner");

        vm.startPrank(notOwner);
        vm.expectRevert();
        _factory.setCreateTokenFee(100);
        vm.stopPrank();
    }

    function testSetCreationFee() public {
        uint256 newFee = 100;

        vm.startPrank(_factoryOwner);
        _factory.setCreateTokenFee(newFee);
        vm.stopPrank();
        assertEq(_factory.createTokenFee(), newFee);
    }

    function testNotOwnerSetCreationFeeToken() public {
        address notOwner = makeAddr("notOwner");
        address newToken = makeAddr("newToken");

        vm.startPrank(notOwner);
        vm.expectRevert();
        _factory.setFeeToken(newToken);
        vm.stopPrank();
    }

    function testSetCreationFeeToken() public {
        address newToken = makeAddr("newToken");

        vm.startPrank(_factoryOwner);
        _factory.setFeeToken(newToken);
        vm.stopPrank();
        assertEq(_factory.feeToken(), newToken);
    }

    function testNotOwnerSetStoryDerivativeWorkflows() public {
        address notOwner = makeAddr("notOwner");
        address newStoryDerivativeWorkflows = makeAddr("newStoryDerivativeWorkflows");

        vm.startPrank(notOwner);
        vm.expectRevert();
        _factory.setStoryDerivativeWorkflows(newStoryDerivativeWorkflows);
        vm.stopPrank();
    }

    function testSetStoryDerivativeWorkflows() public {
        address newStoryDerivativeWorkflows = makeAddr("newStoryDerivativeWorkflows");

        vm.startPrank(_factoryOwner);
        _factory.setStoryDerivativeWorkflows(newStoryDerivativeWorkflows);
        vm.stopPrank();
        assertEq(_factory.storyDerivativeWorkflows(), newStoryDerivativeWorkflows);
    }

    // todo: test createToken
}
