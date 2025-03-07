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
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SpotlightRewardsVault} from "../src/spotlight-rewards-vault/SpotlightRewardsVault.sol";

contract SpotlightTokenFactoryTest is Test {
    address private _factoryOwner;
    MockStoryDerivativeWorkflows private _mockStoryWorkflows;
    uint256 private DEFAULT_CREATION_FEE = 1 ether;

    SpotlightTokenFactory private _factory;
    address private _factoryAddress;

    SpotlightToken private _spotlightTokenImpl;
    SpotlightTokenIPCollection private _tokenIpCollection;
    SpotlightNativeBondingCurve private _bondingCurve;
    SpotlightRewardsVault private _rewardsVault;
    address private constant _piperXRouter = address(0);
    address private constant _piperXFactory = address(0);

    function setUp() public {
        _factoryOwner = makeAddr("factoryOwner");
        _mockStoryWorkflows = new MockStoryDerivativeWorkflows();
        _spotlightTokenImpl = new SpotlightToken();

        vm.startPrank(_factoryOwner);
        _factory = new SpotlightTokenFactory();
        _factoryAddress = address(_factory);
        _tokenIpCollection = new SpotlightTokenIPCollection(_factoryAddress);
        _bondingCurve = new SpotlightNativeBondingCurve(1060848709, 4379701787);
        _rewardsVault = new SpotlightRewardsVault();

        _factory.initialize(
            _factoryOwner,
            DEFAULT_CREATION_FEE,
            address(_tokenIpCollection),
            address(_spotlightTokenImpl),
            address(_bondingCurve),
            address(_mockStoryWorkflows),
            address(_piperXRouter),
            address(_piperXFactory),
            address(_rewardsVault)
        );
        vm.stopPrank();
    }

    function testImplementationIsInitialized() public {
        SpotlightTokenFactory factory = new SpotlightTokenFactory();
        assertFalse(factory.isInitialized());
    }

    function testTokenFactoryConstructor() public view {
        assertEq(_factory.owner(), _factoryOwner);
        assertEq(_factory.createTokenFee(), DEFAULT_CREATION_FEE);
        assertEq(_factory.tokenIpCollection(), address(_tokenIpCollection));
        assertEq(_factory.tokenImplementation(), address(_spotlightTokenImpl));
        assertEq(_factory.bondingCurve(), address(_bondingCurve));
        assertEq(_factory.storyDerivativeWorkflows(), address(_mockStoryWorkflows));
        assertEq(_factory.piperXRouter(), _piperXRouter);
        assertEq(_factory.piperXFactory(), _piperXFactory);
        assertEq(_factory.rewardsVault(), address(_rewardsVault));
    }

    function testNotOwnerSetCreationFee() public {
        address notOwner = makeAddr("notOwner");
        uint256 creationFee = DEFAULT_CREATION_FEE;

        vm.startPrank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, notOwner));
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

    function testNotOwnerSetTokenImplementation() public {
        address notOwner = makeAddr("notOwner");
        address newTokenImplementation = makeAddr("newTokenImplementation");

        vm.startPrank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, notOwner));
        _factory.setTokenImplementation(newTokenImplementation);
        vm.stopPrank();
    }

    function testSetTokenImplementation() public {
        address newTokenImplementation = makeAddr("newTokenImplementation");

        vm.startPrank(_factoryOwner);
        _factory.setTokenImplementation(newTokenImplementation);
        vm.stopPrank();
        assertEq(_factory.tokenImplementation(), newTokenImplementation);
    }

    function testNotOwnerSetBondingCurve() public {
        address notOwner = makeAddr("notOwner");
        address newBondingCurve = makeAddr("bondingCurve");

        vm.startPrank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, notOwner));
        _factory.setBondingCurve(newBondingCurve);
        vm.stopPrank();
    }

    function testSetBondingCurve() public {
        address newBondingCurve = makeAddr("newBondingCurve");

        vm.startPrank(_factoryOwner);
        _factory.setBondingCurve(newBondingCurve);
        vm.stopPrank();
        assertEq(_factory.bondingCurve(), newBondingCurve);
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

    function testCreateTokenSuccess() public {
        uint256 FACTORY_BALANCE_BEFORE = address(_factory).balance;
        uint256 expectedFactoryBalance = FACTORY_BALANCE_BEFORE + DEFAULT_CREATION_FEE;

        address tokenCreator = makeAddr("tokenCreator");
        vm.deal(tokenCreator, 1 ether + DEFAULT_CREATION_FEE);

        uint256 TOKEN_CREATOR_BALANCE_BEFORE = tokenCreator.balance;
        uint256 expectedTokenCreatorBalance = TOKEN_CREATOR_BALANCE_BEFORE - DEFAULT_CREATION_FEE;

        vm.startPrank(tokenCreator);

        (
            address predeployedTokenAddress,
            ISpotlightTokenFactory.TokenCreationData memory tokenCreationData,
            ISpotlightTokenFactory.IntialBuyData memory initialBuyData,
            StoryWorkflowStructs.MakeDerivative memory makeDerivative,
            StoryWorkflowStructs.IPMetadata memory ipMetadata,
            StoryWorkflowStructs.SignatureData memory sigMetadataAndRegister,
            address mockReturnAddress
        ) = _getDummyStructs(tokenCreator, 0);

        vm.expectEmit(false, false, false, true);
        emit ISpotlightTokenFactory.SpotlightTokenCreated(
            predeployedTokenAddress,
            mockReturnAddress,
            tokenCreator,
            tokenCreationData.tokenName,
            tokenCreationData.tokenSymbol,
            tokenCreationData.tokenIpNFTId,
            initialBuyData.initialBuyAmount,
            initialBuyData.initialBuyRecipient,
            DEFAULT_CREATION_FEE,
            address(_factory),
            address(_bondingCurve)
        );

        _factory.createToken{value: tokenCreator.balance}(
            tokenCreationData, initialBuyData, makeDerivative, ipMetadata, sigMetadataAndRegister
        );
        vm.stopPrank();
        assertEq(address(_factory).balance, expectedFactoryBalance);
        assertEq(tokenCreator.balance, expectedTokenCreatorBalance);
        assertEq(_factory.numberOfTokensCreated(tokenCreator), 1);
    }

    function testCreateTokenSuccessWithInitialBuy() public {
        uint256 INITIAL_BUY_AMOUNT = 1 ether;
        uint256 SHOULD_REFUND_EXCESS_IP = 1 ether;
        uint256 TOKEN_CREATOR_BALANCE = (DEFAULT_CREATION_FEE + INITIAL_BUY_AMOUNT + SHOULD_REFUND_EXCESS_IP);

        uint256 protocolTradingFee = INITIAL_BUY_AMOUNT / 100;
        uint256 ipAccountFee = protocolTradingFee / 10;
        uint256 expectedFactoryBalance =
            address(_factory).balance + DEFAULT_CREATION_FEE + (protocolTradingFee - ipAccountFee);
        uint256 expectedTokenCreatorBalance = SHOULD_REFUND_EXCESS_IP;
        uint256 expectedPredeployedTokenBalance = INITIAL_BUY_AMOUNT * 99 / 100;

        address tokenCreator = makeAddr("tokenCreator");
        vm.deal(tokenCreator, TOKEN_CREATOR_BALANCE);
        vm.startPrank(tokenCreator);

        (
            address predeployedTokenAddress,
            ISpotlightTokenFactory.TokenCreationData memory tokenCreationData,
            ISpotlightTokenFactory.IntialBuyData memory initialBuyData,
            StoryWorkflowStructs.MakeDerivative memory makeDerivative,
            StoryWorkflowStructs.IPMetadata memory ipMetadata,
            StoryWorkflowStructs.SignatureData memory sigMetadataAndRegister,
        ) = _getDummyStructs(tokenCreator, 1 ether);

        _factory.createToken{value: TOKEN_CREATOR_BALANCE}(
            tokenCreationData, initialBuyData, makeDerivative, ipMetadata, sigMetadataAndRegister
        );
        vm.stopPrank();

        assertEq(address(_factory).balance, expectedFactoryBalance);
        assertEq(tokenCreator.balance, expectedTokenCreatorBalance);
        assertEq(predeployedTokenAddress.balance, expectedPredeployedTokenBalance);
        assertEq(_factory.numberOfTokensCreated(tokenCreator), 1);
    }

    function testCreateTokenRevertWhenInsufficientBalanceWithInitialBuy() public {
        uint256 INITIAL_BUY_AMOUNT = 0.9 ether;
        uint256 TOKEN_CREATOR_BALANCE = (DEFAULT_CREATION_FEE + INITIAL_BUY_AMOUNT);
        uint256 EXCESS_INITIAL_BUY_AMOUNT = 1 ether;

        uint256 expectedFactoryBalance = address(_factory).balance;
        uint256 expectedPredeployedTokenBalance = 0;

        address tokenCreator = makeAddr("tokenCreator");
        vm.deal(tokenCreator, TOKEN_CREATOR_BALANCE);
        vm.startPrank(tokenCreator);

        (
            address predeployedTokenAddress,
            ISpotlightTokenFactory.TokenCreationData memory tokenCreationData,
            ISpotlightTokenFactory.IntialBuyData memory initialBuyData,
            StoryWorkflowStructs.MakeDerivative memory makeDerivative,
            StoryWorkflowStructs.IPMetadata memory ipMetadata,
            StoryWorkflowStructs.SignatureData memory sigMetadataAndRegister,
        ) = _getDummyStructs(tokenCreator, EXCESS_INITIAL_BUY_AMOUNT);

        vm.expectRevert("SpotlightTokenFactory: Insufficient total amount");
        _factory.createToken{value: TOKEN_CREATOR_BALANCE}(
            tokenCreationData, initialBuyData, makeDerivative, ipMetadata, sigMetadataAndRegister
        );
        vm.stopPrank();

        assertEq(address(_factory).balance, expectedFactoryBalance);
        assertEq(predeployedTokenAddress.balance, expectedPredeployedTokenBalance);
    }

    function testClaimFeeSuccess() public {
        uint256 FACTORY_BALANCE = 1 ether;

        vm.deal(address(_factory), FACTORY_BALANCE);
        vm.startPrank(_factoryOwner);
        _factory.claimFee(address(_factoryOwner));
        vm.stopPrank();

        assertEq(address(_factoryOwner).balance, FACTORY_BALANCE);
        assertEq(address(_factory).balance, 0);
    }

    function testClaimFeeRevertWhenNonOwner() public {
        uint256 FACTORY_BALANCE = 1 ether;

        vm.deal(address(_factory), FACTORY_BALANCE);
        address nonOwner = makeAddr("nonOwner");

        vm.startPrank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, nonOwner));
        _factory.claimFee(address(nonOwner));
        vm.stopPrank();
    }

    function _getDummyStructs(address tokenCreator, uint256 initialBuyAmount)
        internal
        returns (
            address,
            ISpotlightTokenFactory.TokenCreationData memory,
            ISpotlightTokenFactory.IntialBuyData memory,
            StoryWorkflowStructs.MakeDerivative memory,
            StoryWorkflowStructs.IPMetadata memory,
            StoryWorkflowStructs.SignatureData memory,
            address
        )
    {
        address predeployedTokenAddress = _factory.calculateTokenAddress(tokenCreator);
        ISpotlightTokenFactory.TokenCreationData memory tokenCreationData = ISpotlightTokenFactory.TokenCreationData({
            tokenIpNFTId: 1,
            tokenName: "Test Token",
            tokenSymbol: "TEST",
            predeployedTokenAddress: predeployedTokenAddress
        });
        ISpotlightTokenFactory.IntialBuyData memory initialBuyData = ISpotlightTokenFactory.IntialBuyData({
            initialBuyAmount: initialBuyAmount,
            initialBuyRecipient: tokenCreator
        });
        (
            StoryWorkflowStructs.MakeDerivative memory makeDerivative,
            StoryWorkflowStructs.IPMetadata memory ipMetadata,
            StoryWorkflowStructs.SignatureData memory sigMetadataAndRegister
        ) = _mockStoryWorkflows.getMockStructs();

        address mockReturnAddress = makeAddr("mockReturnAddress");
        _mockStoryWorkflows.setMockReturnAddress(mockReturnAddress);

        return (
            predeployedTokenAddress,
            tokenCreationData,
            initialBuyData,
            makeDerivative,
            ipMetadata,
            sigMetadataAndRegister,
            mockReturnAddress
        );
    }
}
