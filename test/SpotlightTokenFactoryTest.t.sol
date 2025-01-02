// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import {SpotlightToken} from "../src/spotlight-token/SpotlightToken.sol";
import {SpotlightTokenIPCollection} from "../src/spotlight-token-collection/SpotlightTokenIPCollection.sol";
import {SpotlightTokenFactory} from "../src/spotlight-token-factory/SpotlightTokenFactory.sol";
import {MockStoryDerivativeWorkflows} from "./mocks/MockStoryDerivativeWorkflows.sol";
import {ISpotlightTokenFactory} from "../src/spotlight-token-factory/ISpotlightTokenFactory.sol";
import {StoryWorkflowStructs} from "../src/spotlight-token-factory/story-workflow-interfaces/StoryWorkflowStructs.sol";
import {SpotlightNativeBondingCurve} from "../src/spotlight-bonding-curve/SpotlightNativeBondingCurve.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

contract SpotlightTokenFactoryTest is Test {
    address private _factoryOwner;
    MockStoryDerivativeWorkflows private _mockStoryWorkflows;
    uint256 private DEFAULT_CREATION_FEE = 1 ether;

    SpotlightTokenFactory private _factory;
    address private _factoryAddress;

    SpotlightTokenIPCollection private _tokenIpCollection;
    SpotlightNativeBondingCurve private _bondingCurve;
    UpgradeableBeacon private _spotlightTokenBeacon;

    address private constant Wrapper_IP = 0xe8CabF9d1FFB6CE23cF0a86641849543ec7BD7d5;

    function setUp() public {
        _factoryOwner = makeAddr("factoryOwner");
        _mockStoryWorkflows = new MockStoryDerivativeWorkflows();
        SpotlightToken spotlightTokenImpl = new SpotlightToken();

        vm.startPrank(_factoryOwner);
        _factory = new SpotlightTokenFactory();
        _factoryAddress = address(_factory);
        _tokenIpCollection = new SpotlightTokenIPCollection(_factoryAddress);
        _bondingCurve = new SpotlightNativeBondingCurve(1060848709, 4379701787);
        _spotlightTokenBeacon = new UpgradeableBeacon(address(spotlightTokenImpl), _factoryOwner);

        _factory.initialize(
            _factoryOwner,
            DEFAULT_CREATION_FEE,
            address(_tokenIpCollection),
            address(_spotlightTokenBeacon),
            address(_bondingCurve),
            Wrapper_IP,
            address(_mockStoryWorkflows),
            address(0),
            address(0)
        );
        vm.stopPrank();
    }

    function testTokenFactoryConstructor() public view {
        assertEq(_factory.owner(), _factoryOwner);
        assertEq(_factory.createTokenFee(), DEFAULT_CREATION_FEE);
        assertEq(_factory.storyDerivativeWorkflows(), address(_mockStoryWorkflows));
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
        uint256 creationFee = DEFAULT_CREATION_FEE;

        vm.startPrank(notOwner);
        vm.expectRevert();
        _factory.setCreateTokenFee(creationFee);
        vm.stopPrank();
    }

    function testSetCreationFee() public {
        uint256 creationFee = DEFAULT_CREATION_FEE;

        vm.startPrank(_factoryOwner);
        _factory.setCreateTokenFee(creationFee);
        vm.stopPrank();
        assertEq(_factory.createTokenFee(), creationFee);
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

    function testCalculateTokenAddress() public {
        address tokenCreator = makeAddr("tokenCreator");
        vm.startPrank(tokenCreator);
        address tokenAddress = _factory.calculateTokenAddress(tokenCreator);
        vm.stopPrank();

        assertTrue(tokenAddress != address(0));
    }

    function testDifferentCreatorsShouldHaveDifferentTokenAddresses() public {
        address tokenCreator1 = makeAddr("tokenCreator1");
        address tokenCreator2 = makeAddr("tokenCreator2");

        vm.startPrank(tokenCreator1);
        address tokenAddress1 = _factory.calculateTokenAddress(tokenCreator1);
        vm.stopPrank();

        vm.startPrank(tokenCreator2);
        address tokenAddress2 = _factory.calculateTokenAddress(tokenCreator2);
        vm.stopPrank();

        assertTrue(tokenAddress1 != address(0));
        assertTrue(tokenAddress2 != address(0));
        assertTrue(tokenAddress1 != tokenAddress2);
    }

    function testCreateToken() public {
        address tokenCreator = makeAddr("tokenCreator");
        vm.deal(tokenCreator, 2 ether);
        vm.startPrank(tokenCreator);

        address predeployedTokenAddress = _factory.calculateTokenAddress(tokenCreator);

        ISpotlightTokenFactory.TokenCreationData memory tokenCreationData = ISpotlightTokenFactory.TokenCreationData({
            tokenIpNFTId: 1,
            tokenName: "Test Token",
            tokenSymbol: "TEST",
            predeployedTokenAddress: predeployedTokenAddress
        });
        ISpotlightTokenFactory.IntialBuyData memory initialBuyData =
            ISpotlightTokenFactory.IntialBuyData({initialBuyAmount: 1, initialBuyRecipient: tokenCreator});
        (
            StoryWorkflowStructs.MakeDerivative memory makeDerivative,
            StoryWorkflowStructs.IPMetadata memory ipMetadata,
            StoryWorkflowStructs.SignatureData memory sigMetadata,
            StoryWorkflowStructs.SignatureData memory sigRegister
        ) = _mockStoryWorkflows.getMockStructs();

        _factory.createToken{value: DEFAULT_CREATION_FEE}(
            tokenCreationData, initialBuyData, makeDerivative, ipMetadata, sigMetadata, sigRegister
        );
        vm.stopPrank();

    }
}
