// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {SpotlightToken} from "../src/spotlight-token/SpotlightToken.sol";
import {MarketType, MarketState} from "../src/spotlight-token/ISpotlightToken.sol";
import {SpotlightTokenIPCollection} from "../src/spotlight-token-collection/SpotlightTokenIPCollection.sol";
import {SpotlightTokenFactory} from "../src/spotlight-token-factory/SpotlightTokenFactory.sol";
import {MockStoryDerivativeWorkflows} from "./mocks/MockStoryDerivativeWorkflows.sol";
import {ISpotlightTokenFactory} from "../src/spotlight-token-factory/ISpotlightTokenFactory.sol";
import {StoryWorkflowStructs} from "../src/spotlight-token-factory/story-workflow-interfaces/StoryWorkflowStructs.sol";
import {SpotlightNativeBondingCurve} from "../src/spotlight-bonding-curve/SpotlightNativeBondingCurve.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
import {ISpotlightToken} from "../src/spotlight-token/ISpotlightToken.sol";
import {SpotlightRewardsVault} from "../src/spotlight-rewards-vault/SpotlightRewardsVault.sol";
import {IUniswapV2Factory} from "../src/interfaces/IUniswapV2Factory.sol";

contract SpotlightTokenTest is Test {
    address private constant WRAPPER_IP = 0x1514000000000000000000000000000000000000;
    address private constant PIPERX_V2_ROUTER = 0x674eFAa8C50cBEF923ECe625d3c276B7Bb1c16fB;
    address private constant PIPERX_V2_FACTORY = 0x6D3e2f58954bf4E1d0C4bA26a85a1b49b2e244C6;

    // @dev following constants are from SpotlightTokenStorage
    uint256 private constant DEFAULT_CREATION_FEE = 0.1 ether;
    uint256 public constant TOTAL_FEE_BPS = 100;
    uint256 public constant BONDING_CURVE_SUPPLY = 800_000_000e18; // 0.8 billion
    uint256 public constant MAX_TOTAL_SUPPLY = 1_000_000_000e18; // 1 billion
    uint256 public constant GRADUATE_MARKET_AMOUNT = 3745 ether;
    uint256 public constant IP_ACCOUNT_FEE_BPS = 1_000; // 10%

    SpotlightTokenFactory private _factory;
    SpotlightTokenIPCollection private _tokenIpCollection;
    SpotlightNativeBondingCurve private _bondingCurve;
    SpotlightToken private _token;
    SpotlightToken private _tokenCreatedWithIPAccount;
    MockStoryDerivativeWorkflows private _mockStoryWorkflows;
    SpotlightRewardsVault private _rewardsVault;

    address private _factoryOwner;
    address private _tokenCreator;
    address private _tokenAddress;
    address private _buyer;

    function setUp() public {
        _mockStoryWorkflows = new MockStoryDerivativeWorkflows();
        SpotlightToken spotlightTokenImpl = new SpotlightToken();

        _factoryOwner = makeAddr("factoryOwner");
        vm.startPrank(_factoryOwner);
        _factory = new SpotlightTokenFactory();
        _tokenIpCollection = new SpotlightTokenIPCollection(address(_factory));
        _bondingCurve = new SpotlightNativeBondingCurve(840_000_000_000, 3_500_000_000);
        _rewardsVault = new SpotlightRewardsVault();

        _factory.initialize(
            _factoryOwner,
            DEFAULT_CREATION_FEE,
            address(_tokenIpCollection),
            address(spotlightTokenImpl),
            address(_bondingCurve),
            address(_mockStoryWorkflows),
            PIPERX_V2_ROUTER,
            PIPERX_V2_FACTORY,
            address(_rewardsVault)
        );
        vm.stopPrank();

        _tokenCreator = makeAddr("tokenCreator");
        vm.deal(_tokenCreator, 2 ether);
        vm.startPrank(_tokenCreator);

        ISpotlightTokenFactory.IntialBuyData memory initialBuyData =
            ISpotlightTokenFactory.IntialBuyData({initialBuyAmount: 0, initialBuyRecipient: _tokenCreator});
        (
            StoryWorkflowStructs.MakeDerivative memory makeDerivative,
            StoryWorkflowStructs.IPMetadata memory ipMetadata,
            StoryWorkflowStructs.SignatureData memory sigMetadataAndRegister
        ) = _mockStoryWorkflows.getMockStructs();

        address predeployedTokenAddress = _factory.calculateTokenAddress(_tokenCreator);
        ISpotlightTokenFactory.TokenCreationData memory tokenCreationData = ISpotlightTokenFactory.TokenCreationData({
            tokenIpNFTId: 1,
            tokenName: "Test Token",
            tokenSymbol: "TEST",
            predeployedTokenAddress: predeployedTokenAddress
        });

        (_tokenAddress,) = _factory.createToken{value: DEFAULT_CREATION_FEE}(
            tokenCreationData, initialBuyData, makeDerivative, ipMetadata, sigMetadataAndRegister
        );
        _token = SpotlightToken(payable(_tokenAddress));

        address predeployedTokenAddressWithIPAccount = _factory.calculateTokenAddress(_tokenCreator);
        ISpotlightTokenFactory.TokenCreationData memory tokenCreationDataWithIPAccount = ISpotlightTokenFactory
            .TokenCreationData({
            tokenIpNFTId: 2,
            tokenName: "Test Token",
            tokenSymbol: "TEST",
            predeployedTokenAddress: predeployedTokenAddressWithIPAccount
        });

        address tokenCreatedWithIPAccount;
        (tokenCreatedWithIPAccount,) = _factory.createToken{value: DEFAULT_CREATION_FEE}(
            tokenCreationDataWithIPAccount, initialBuyData, makeDerivative, ipMetadata, sigMetadataAndRegister
        );
        _tokenCreatedWithIPAccount = SpotlightToken(payable(tokenCreatedWithIPAccount));
        vm.stopPrank();

        _buyer = makeAddr("buyer");
    }

    function testImplementationIsInitialized() public {
        SpotlightToken token = new SpotlightToken();
        assertFalse(token.isInitialized());
    }

    function testProxyInitialization() public {
        SpotlightToken token = new SpotlightToken();
        SpotlightToken proxy = SpotlightToken(payable(Clones.clone(address(token))));
        assertFalse(proxy.isInitialized());

        vm.expectRevert("SpotlightToken: Not initialized");
        proxy.buyWithIP(address(0), 0, MarketType.BONDING_CURVE);
        vm.expectRevert("SpotlightToken: Not initialized");
        proxy.buyToken(0, address(0), MarketType.BONDING_CURVE);
        vm.expectRevert("SpotlightToken: Not initialized");
        proxy.sellToken(0, address(0), 0, MarketType.BONDING_CURVE);

        proxy.initialize(
            "Test Token",
            "TEST",
            _tokenCreator,
            address(_bondingCurve),
            address(_factory),
            address(0x7D0876367577F59919489856D2f85458a26A243D),
            address(_rewardsVault),
            address(PIPERX_V2_ROUTER),
            address(PIPERX_V2_FACTORY)
        );
    }

    function testGetterFunctions() public view {
        assertEq(_token.name(), "Test Token");
        assertEq(_token.symbol(), "TEST");
        assertEq(_token.tokenCreator(), _tokenCreator);
        assertEq(_token.protocolFeeRecipient(), address(_factory));
        assertEq(_token.bondingCurve(), address(_bondingCurve));
        assertEq(_token.rewardsVault(), address(_rewardsVault));
        assertEq(_token.piperXRouter(), PIPERX_V2_ROUTER);
        assertEq(_token.piperXFactory(), PIPERX_V2_FACTORY);
    }

    function testBuyWithIPSuccessInBondingCurvePhase() public {
        uint256 USER_BUY_AMOUNT = 1 ether;
        uint256 PROTOCOL_TRADING_FEE = _calculateFee(USER_BUY_AMOUNT, TOTAL_FEE_BPS);
        uint256 TOKEN_CONTRACT_BALANCE_BEFORE = address(_token).balance;
        uint256 FACTORY_BALANCE_BEFORE = address(_factory).balance;
        uint256 protocolTradingFeeForFactory =
            PROTOCOL_TRADING_FEE - _calculateFee(PROTOCOL_TRADING_FEE, IP_ACCOUNT_FEE_BPS);
        uint256 expectedTokenReceived = _token.getIPBuyQuoteWithFee(USER_BUY_AMOUNT);
        uint256 expectedContractIPBalance = TOKEN_CONTRACT_BALANCE_BEFORE + USER_BUY_AMOUNT - PROTOCOL_TRADING_FEE;
        uint256 expectedFactoryBalance = FACTORY_BALANCE_BEFORE + protocolTradingFeeForFactory;

        vm.deal(_buyer, USER_BUY_AMOUNT);
        vm.startPrank(_buyer);

        vm.expectEmit(false, false, false, true);
        emit ISpotlightToken.SpotlightTokenBought(
            _buyer,
            _buyer,
            USER_BUY_AMOUNT,
            PROTOCOL_TRADING_FEE,
            USER_BUY_AMOUNT - PROTOCOL_TRADING_FEE,
            expectedTokenReceived,
            _token.totalSupply() + expectedTokenReceived
        );

        _token.buyWithIP{value: USER_BUY_AMOUNT}(_buyer, 0, MarketType.BONDING_CURVE);
        vm.stopPrank();

        assertEq(_token.balanceOf(_buyer), expectedTokenReceived);
        assertEq(address(_token).balance, expectedContractIPBalance);
        assertEq(address(_factory).balance, expectedFactoryBalance);
    }

    function testBuyWithIPSuccessGraduateMarketInBondingCurvePhase() public {
        uint256 USER_BUY_AMOUNT = 3745 ether;
        uint256 PROTOCOL_TRADING_FEE = _calculateFee(USER_BUY_AMOUNT, TOTAL_FEE_BPS);
        uint256 expectedIPSpent = _bondingCurve.getTargetTokenBuyQuote(0, BONDING_CURVE_SUPPLY);
        uint256 expectedRefundBuyerReceived = USER_BUY_AMOUNT - PROTOCOL_TRADING_FEE - expectedIPSpent;

        vm.deal(_buyer, USER_BUY_AMOUNT);
        vm.startPrank(_buyer);
        vm.expectEmit(false, false, false, false); // only verify that the event was emitted, ignoring parameter values
        emit ISpotlightToken.SpotlightTokenGraduated(address(0), address(0), 0, 0, 0, MarketType.PIPERX_POOL);

        _token.buyWithIP{value: USER_BUY_AMOUNT}(_buyer, 0, MarketType.BONDING_CURVE);
        vm.stopPrank();

        MarketState memory state = _token.state();

        // token status check
        assertEq(_token.totalSupply(), MAX_TOTAL_SUPPLY);
        assertEq(address(_token).balance, 0);

        // marketType should be PIPERX_POOL
        assertTrue(state.marketType == MarketType.PIPERX_POOL);
        assertTrue(state.marketAddress != address(_token));

        // buyer should receive a refund if the market graduates and the user's buy amount exceeds the maximum amount
        assertApproxEqAbs(_buyer.balance, expectedRefundBuyerReceived, 2e18);
    }

    function testBuyWithIPSuccessWithDisperseFeeToIPAccountOwner() public {
        uint256 USER_BUY_AMOUNT = 1 ether;
        uint256 protocolTradingFee = _calculateFee(USER_BUY_AMOUNT, TOTAL_FEE_BPS);
        uint256 ipAccountReward = _calculateFee(protocolTradingFee, IP_ACCOUNT_FEE_BPS);
        uint256 expectedProtocolRewardsBalance = address(_rewardsVault).balance + ipAccountReward;
        uint256 expectedFactoryBalance = address(_factory).balance + (protocolTradingFee - ipAccountReward);

        vm.deal(_buyer, USER_BUY_AMOUNT);
        vm.startPrank(_buyer);
        _tokenCreatedWithIPAccount.buyWithIP{value: USER_BUY_AMOUNT}(_buyer, 0, MarketType.BONDING_CURVE);
        vm.stopPrank();

        assertEq(address(_factory).balance, expectedFactoryBalance);
        assertEq(address(_rewardsVault).balance, expectedProtocolRewardsBalance);
    }

    function testBuyWithIPSuccessInPiperXPhase() public {
        address graduateMarket = makeAddr("graduateMarket");
        vm.deal(graduateMarket, GRADUATE_MARKET_AMOUNT);
        vm.startPrank(graduateMarket);
        _token.buyWithIP{value: GRADUATE_MARKET_AMOUNT}(_buyer, 0, MarketType.BONDING_CURVE);
        vm.stopPrank();

        MarketState memory state = _token.state();
        assertTrue(state.marketType == MarketType.PIPERX_POOL);

        vm.deal(_buyer, 1 ether);
        vm.startPrank(_buyer);
        _token.buyWithIP{value: 1 ether}(_buyer, 0, MarketType.PIPERX_POOL);
        vm.stopPrank();
    }

    function testBuyWithIPRevertsWhenMarketTypeMismatch() public {
        vm.deal(_buyer, 1 ether);
        vm.startPrank(_buyer);

        vm.expectRevert(abi.encodeWithSelector(SpotlightToken.InvalidMarketType.selector));
        _token.buyWithIP{value: 1 ether}(_buyer, 0, MarketType.PIPERX_POOL);

        vm.stopPrank();
    }

    function testBuyWithIPRevertsWhenAmountTooSmall() public {
        uint256 insufficientAmount = 0.00001 ether;
        vm.deal(_buyer, insufficientAmount);
        vm.startPrank(_buyer);

        vm.expectRevert(abi.encodeWithSelector(SpotlightToken.IPAmountTooSmall.selector));
        _token.buyWithIP{value: insufficientAmount}(_buyer, 0, MarketType.BONDING_CURVE);

        vm.stopPrank();
    }

    function testBuyWithIPRevertsWhenRecipientIsZero() public {
        vm.deal(_buyer, 1 ether);
        vm.startPrank(_buyer);

        vm.expectRevert(abi.encodeWithSelector(SpotlightToken.AddressZero.selector));
        _token.buyWithIP{value: 1 ether}(address(0), 0, MarketType.BONDING_CURVE);

        vm.stopPrank();
    }

    function testBuyWithIPRevertsWhenSlippageExceeded() public {
        vm.deal(_buyer, 1 ether);
        vm.startPrank(_buyer);

        uint256 exceededTokenOut = _token.getIPBuyQuoteWithFee(1.1 ether);
        vm.expectRevert(abi.encodeWithSelector(SpotlightToken.SlippageBoundsExceeded.selector));
        _token.buyWithIP{value: 1 ether}(_buyer, exceededTokenOut, MarketType.BONDING_CURVE);

        vm.stopPrank();
    }

    function testBuyTokenSuccessInBondingCurvePhase() public {
        uint256 USER_BUY_TOKEN_AMOUNT = 400_000_000e18;
        uint256 TOKEN_CONTRACT_BALANCE_BEFORE = address(_token).balance;
        uint256 FACTORY_BALANCE_BEFORE = address(_factory).balance;
        uint256 ipIn = _token.getTokenBuyQuote(USER_BUY_TOKEN_AMOUNT);
        uint256 protocolTradingFee = _calculateFee(ipIn, TOTAL_FEE_BPS);
        uint256 protocolTradingFeeForFactory =
            protocolTradingFee - _calculateFee(protocolTradingFee, IP_ACCOUNT_FEE_BPS);
        uint256 ipInWithFee = ipIn + protocolTradingFee;
        uint256 expectedContractIPBalance = TOKEN_CONTRACT_BALANCE_BEFORE + ipIn;
        uint256 expectedFactoryBalance = FACTORY_BALANCE_BEFORE + protocolTradingFeeForFactory;

        vm.deal(_buyer, ipInWithFee);
        vm.startPrank(_buyer);

        vm.expectEmit(false, false, false, true);
        emit ISpotlightToken.SpotlightTokenBought(
            _buyer,
            _buyer,
            ipInWithFee,
            protocolTradingFee,
            ipInWithFee - protocolTradingFee,
            USER_BUY_TOKEN_AMOUNT,
            _token.totalSupply() + USER_BUY_TOKEN_AMOUNT
        );

        _token.buyToken{value: ipInWithFee}(USER_BUY_TOKEN_AMOUNT, _buyer, MarketType.BONDING_CURVE);
        vm.stopPrank();

        assertEq(_token.balanceOf(_buyer), USER_BUY_TOKEN_AMOUNT);
        assertEq(address(_token).balance, expectedContractIPBalance);
        assertEq(address(_factory).balance, expectedFactoryBalance);
    }

    function testBuyTokenSuccessGraduateMarketInBondingCurvePhase() public {
        uint256 USER_BUY_TOKEN_AMOUNT = 800_000_000e18;
        uint256 ipInWithFee = _token.getTokenBuyQuoteWithFee(USER_BUY_TOKEN_AMOUNT);
        uint256 expectedRefundBuyerReceived = 1 ether;
        uint256 userBuyAmount = ipInWithFee + expectedRefundBuyerReceived;

        vm.deal(_buyer, userBuyAmount);
        vm.startPrank(_buyer);

        vm.expectEmit(false, false, false, false);
        emit ISpotlightToken.SpotlightTokenGraduated(address(0), address(0), 0, 0, 0, MarketType.PIPERX_POOL);

        _token.buyToken{value: userBuyAmount}(USER_BUY_TOKEN_AMOUNT, _buyer, MarketType.BONDING_CURVE);
        vm.stopPrank();

        MarketState memory state = _token.state();

        // token status check
        assertEq(_token.totalSupply(), MAX_TOTAL_SUPPLY);
        assertEq(address(_token).balance, 0);

        // marketType should be PIPERX_POOL
        assertTrue(state.marketType == MarketType.PIPERX_POOL);
        assertTrue(state.marketAddress != address(_token));

        // buyer should receive a refund if the market graduates and the user's buy amount exceeds the maximum amount
        assertApproxEqAbs(_buyer.balance, expectedRefundBuyerReceived, 1e18);
    }

    function testBuyTokenSuccessWithDisperseFeeToIPAccountOwner() public {
        uint256 USER_BUY_TOKEN_AMOUNT = 400_000_000e18;
        uint256 FACTORY_BALANCE_BEFORE = address(_factory).balance;
        uint256 ipIn = _tokenCreatedWithIPAccount.getTokenBuyQuote(USER_BUY_TOKEN_AMOUNT);
        uint256 protocolTradingFee = _calculateFee(ipIn, TOTAL_FEE_BPS);
        uint256 ipInWithFee = ipIn + protocolTradingFee;
        uint256 ipAccountReward = _calculateFee(protocolTradingFee, IP_ACCOUNT_FEE_BPS);
        uint256 expectedProtocolRewardsBalance = address(_rewardsVault).balance + ipAccountReward;
        uint256 expectedFactoryBalance = FACTORY_BALANCE_BEFORE + (protocolTradingFee - ipAccountReward);

        vm.deal(_buyer, ipInWithFee);
        vm.startPrank(_buyer);
        _tokenCreatedWithIPAccount.buyToken{value: ipInWithFee}(USER_BUY_TOKEN_AMOUNT, _buyer, MarketType.BONDING_CURVE);
        vm.stopPrank();

        assertEq(address(_factory).balance, expectedFactoryBalance);
        assertEq(address(_rewardsVault).balance, expectedProtocolRewardsBalance);
    }

    function testBuyTokenSuccessInPiperXPhase() public {
        uint256 GRADUATE_TOKEN_AMOUNT = BONDING_CURVE_SUPPLY;
        uint256 graduateIpInWithFee = _token.getTokenBuyQuoteWithFee(GRADUATE_TOKEN_AMOUNT);

        address graduateMarket = makeAddr("graduateMarket");
        vm.deal(graduateMarket, graduateIpInWithFee);
        vm.startPrank(graduateMarket);
        _token.buyToken{value: graduateIpInWithFee}(GRADUATE_TOKEN_AMOUNT, graduateMarket, MarketType.BONDING_CURVE);
        vm.stopPrank();

        MarketState memory state = _token.state();
        assertTrue(state.marketType == MarketType.PIPERX_POOL);

        uint256 USER_BUY_TOKEN_AMOUNT = 100_000_000e18;
        address[] memory paths = new address[](2);
        paths[0] = address(WRAPPER_IP);
        paths[1] = address(_token);
        uint256[] memory amounts = IUniswapV2Router02(PIPERX_V2_ROUTER).getAmountsIn(USER_BUY_TOKEN_AMOUNT, paths);
        uint256 ipInWithFee = amounts[0];
        vm.deal(_buyer, ipInWithFee);
        vm.startPrank(_buyer);
        _token.buyToken{value: ipInWithFee}(USER_BUY_TOKEN_AMOUNT, _buyer, MarketType.PIPERX_POOL);
        vm.stopPrank();
    }

    function testBuyTokenRevertsWhenMarketTypeMismatch() public {
        uint256 tokenAmount = _token.getTokenBuyQuote(1 ether);

        vm.deal(_buyer, 1 ether);
        vm.startPrank(_buyer);

        vm.expectRevert(abi.encodeWithSelector(SpotlightToken.InvalidMarketType.selector));
        _token.buyToken{value: 1 ether}(tokenAmount, _buyer, MarketType.PIPERX_POOL);

        vm.stopPrank();
    }

    function testBuyTokenRevertsWhenAmountTooSmall() public {
        uint256 insufficientAmount = 0.00001 ether;
        uint256 tokenAmount = _token.getTokenBuyQuote(insufficientAmount);

        vm.deal(_buyer, insufficientAmount);
        vm.startPrank(_buyer);

        vm.expectRevert(abi.encodeWithSelector(SpotlightToken.IPAmountTooSmall.selector));
        _token.buyToken{value: insufficientAmount}(tokenAmount, _buyer, MarketType.BONDING_CURVE);

        vm.stopPrank();
    }

    function testBuyTokenRevertsWhenRecipientIsZero() public {
        uint256 tokenAmount = _token.getTokenBuyQuote(1 ether);

        vm.deal(_buyer, 1 ether);
        vm.startPrank(_buyer);

        vm.expectRevert(abi.encodeWithSelector(SpotlightToken.AddressZero.selector));
        _token.buyToken{value: 1 ether}(tokenAmount, address(0), MarketType.BONDING_CURVE);

        vm.stopPrank();
    }

    function testBuyTokenRevertsWhenSlippageExceeded() public {
        vm.deal(_buyer, 1 ether);
        vm.startPrank(_buyer);

        uint256 tokenAmount = _token.getIPBuyQuoteWithFee(1.1 ether);
        vm.expectRevert(abi.encodeWithSelector(SpotlightToken.SlippageBoundsExceeded.selector));
        _token.buyToken{value: 1 ether}(tokenAmount, _buyer, MarketType.BONDING_CURVE);

        vm.stopPrank();
    }

    function testSellTokenSuccessInBondingCurvePhase() public {
        uint256 USER_BUY_TOKEN_AMOUNT = 600_000_000e18;
        uint256 ipInWithFee = _token.getTokenBuyQuoteWithFee(USER_BUY_TOKEN_AMOUNT);

        vm.deal(_buyer, ipInWithFee);
        vm.startPrank(_buyer);
        _token.buyToken{value: ipInWithFee}(USER_BUY_TOKEN_AMOUNT, _buyer, MarketType.BONDING_CURVE);
        vm.stopPrank();

        assertEq(_token.balanceOf(_buyer), USER_BUY_TOKEN_AMOUNT);

        uint256 BUYER_BALANCE_BEFORE = _buyer.balance;
        uint256 USER_SELL_TOKEN_AMOUNT = 500_000_000e18;
        uint256 expectedBuyerTokenBalance = USER_BUY_TOKEN_AMOUNT - USER_SELL_TOKEN_AMOUNT;
        uint256 ipOut = _token.getTokenSellQuote(USER_SELL_TOKEN_AMOUNT);
        uint256 fee = _calculateFee(ipOut, TOTAL_FEE_BPS);
        uint256 expectedBuyerBalance = BUYER_BALANCE_BEFORE + ipOut - fee;

        vm.startPrank(_buyer);

        vm.expectEmit(false, false, false, true);
        emit ISpotlightToken.SpotlightTokenSold(
            _buyer,
            _buyer,
            ipOut - fee,
            fee,
            ipOut,
            USER_SELL_TOKEN_AMOUNT,
            _token.totalSupply() - USER_SELL_TOKEN_AMOUNT
        );

        _token.sellToken(USER_SELL_TOKEN_AMOUNT, _buyer, 0, MarketType.BONDING_CURVE);
        vm.stopPrank();

        assertEq(_token.balanceOf(_buyer), expectedBuyerTokenBalance);
        assertEq(_buyer.balance, expectedBuyerBalance);
    }

    function testSellTokenSuccessWithDisperseFeeToIPAccountOwner() public {
        uint256 USER_BUY_TOKEN_AMOUNT = 600_000_000e18;
        uint256 ipInWithFee = _tokenCreatedWithIPAccount.getTokenBuyQuoteWithFee(USER_BUY_TOKEN_AMOUNT);

        vm.deal(_buyer, ipInWithFee);
        vm.startPrank(_buyer);
        _tokenCreatedWithIPAccount.buyToken{value: ipInWithFee}(USER_BUY_TOKEN_AMOUNT, _buyer, MarketType.BONDING_CURVE);
        vm.stopPrank();
        assertEq(_tokenCreatedWithIPAccount.balanceOf(_buyer), USER_BUY_TOKEN_AMOUNT);

        uint256 USER_SELL_TOKEN_AMOUNT = 500_000_000e18;
        uint256 ipOut = _tokenCreatedWithIPAccount.getTokenSellQuote(USER_SELL_TOKEN_AMOUNT);
        uint256 fee = _calculateFee(ipOut, TOTAL_FEE_BPS);
        uint256 ipAccountReward = _calculateFee(fee, IP_ACCOUNT_FEE_BPS);
        uint256 expectedProtocolRewardsBalance = address(_rewardsVault).balance + ipAccountReward;
        uint256 expectedFactoryBalance = address(_factory).balance + (fee - ipAccountReward);

        vm.startPrank(_buyer);
        _tokenCreatedWithIPAccount.sellToken(USER_SELL_TOKEN_AMOUNT, _buyer, 0, MarketType.BONDING_CURVE);
        vm.stopPrank();

        assertEq(address(_rewardsVault).balance, expectedProtocolRewardsBalance);
        assertEq(address(_factory).balance, expectedFactoryBalance);
    }

    function testSellTokenSuccessInPiperXPhase() public {
        uint256 GRADUATE_TOKEN_AMOUNT = BONDING_CURVE_SUPPLY;
        uint256 graduateIpInWithFee = _token.getTokenBuyQuoteWithFee(GRADUATE_TOKEN_AMOUNT);

        address graduateMarket = makeAddr("graduateMarket");
        vm.deal(graduateMarket, graduateIpInWithFee);
        vm.startPrank(graduateMarket);
        _token.buyToken{value: graduateIpInWithFee}(GRADUATE_TOKEN_AMOUNT, graduateMarket, MarketType.BONDING_CURVE);
        vm.stopPrank();

        MarketState memory state = _token.state();
        assertTrue(state.marketType == MarketType.PIPERX_POOL);

        uint256 USER_BUY_TOKEN_AMOUNT = 100_000_000e18;
        vm.deal(_buyer, 10_000 ether);
        vm.startPrank(_buyer);
        _token.buyToken{value: 10_000 ether}(USER_BUY_TOKEN_AMOUNT, _buyer, MarketType.PIPERX_POOL);
        vm.stopPrank();
        assertEq(_token.balanceOf(_buyer), USER_BUY_TOKEN_AMOUNT);

        uint256 USER_SELL_TOKEN_AMOUNT = USER_BUY_TOKEN_AMOUNT / 2;
        address[] memory paths = new address[](2);
        paths[0] = address(_token);
        paths[1] = address(WRAPPER_IP);
        uint256[] memory amounts = IUniswapV2Router02(PIPERX_V2_ROUTER).getAmountsOut(USER_SELL_TOKEN_AMOUNT, paths);
        uint256 expectedIpOut = amounts[1];

        vm.deal(_buyer, 1 ether);
        uint256 buyerBalanceBefore = _buyer.balance;
        vm.startPrank(_buyer);
        _token.sellToken(USER_SELL_TOKEN_AMOUNT, _buyer, 0, MarketType.PIPERX_POOL);
        vm.stopPrank();

        assertEq(_token.balanceOf(_buyer), USER_BUY_TOKEN_AMOUNT - USER_SELL_TOKEN_AMOUNT);
        assertEq(_buyer.balance, buyerBalanceBefore + expectedIpOut);
    }

    function testSellTokenRevertsWhenMarketTypeMismatch() public {
        vm.deal(_buyer, 1 ether);
        vm.startPrank(_buyer);

        vm.expectRevert(abi.encodeWithSelector(SpotlightToken.InvalidMarketType.selector));
        _token.sellToken(1_000_000_000e18, _buyer, 0, MarketType.PIPERX_POOL);

        vm.stopPrank();
    }

    function testSellTokenRevertsWhenRecipientIsZero() public {
        vm.deal(_buyer, 1 ether);
        vm.startPrank(_buyer);

        vm.expectRevert(abi.encodeWithSelector(SpotlightToken.AddressZero.selector));
        _token.sellToken(1_000_000_000e18, address(0), 0, MarketType.BONDING_CURVE);

        vm.stopPrank();
    }

    function testSellTokenRevertsWhenInsufficientLiquidity() public {
        uint256 USER_BUY_TOKEN_AMOUNT = 600_000_000e18;
        uint256 ipInWithFee = _token.getTokenBuyQuoteWithFee(USER_BUY_TOKEN_AMOUNT);

        vm.deal(_buyer, ipInWithFee);
        vm.startPrank(_buyer);
        _token.buyToken{value: ipInWithFee}(USER_BUY_TOKEN_AMOUNT, _buyer, MarketType.BONDING_CURVE);
        vm.stopPrank();

        assertEq(_token.balanceOf(_buyer), USER_BUY_TOKEN_AMOUNT);

        uint256 USER_SELL_TOKEN_AMOUNT = USER_BUY_TOKEN_AMOUNT + 100_000_000e18;

        vm.startPrank(_buyer);
        vm.expectRevert(abi.encodeWithSelector(SpotlightToken.InsufficientLiquidity.selector));
        _token.sellToken(USER_SELL_TOKEN_AMOUNT, _buyer, 0, MarketType.BONDING_CURVE);
        vm.stopPrank();
    }

    function testSellTokenRevertsWhenSlippageExceeded() public {
        uint256 USER_BUY_TOKEN_AMOUNT = 600_000_000e18;
        uint256 ipInWithFee = _token.getTokenBuyQuoteWithFee(USER_BUY_TOKEN_AMOUNT);

        vm.deal(_buyer, ipInWithFee);
        vm.startPrank(_buyer);
        _token.buyToken{value: ipInWithFee}(USER_BUY_TOKEN_AMOUNT, _buyer, MarketType.BONDING_CURVE);
        vm.stopPrank();

        assertEq(_token.balanceOf(_buyer), USER_BUY_TOKEN_AMOUNT);

        uint256 USER_SELL_TOKEN_AMOUNT = USER_BUY_TOKEN_AMOUNT / 2;
        uint256 exceededMinIpOut = _token.getTokenSellQuoteWithFee(USER_SELL_TOKEN_AMOUNT + 100_000_000e18);

        vm.startPrank(_buyer);
        vm.expectRevert(abi.encodeWithSelector(SpotlightToken.SlippageBoundsExceeded.selector));
        _token.sellToken(USER_SELL_TOKEN_AMOUNT, _buyer, exceededMinIpOut, MarketType.BONDING_CURVE);
        vm.stopPrank();
    }

    function _calculateFee(uint256 amount, uint256 bps) internal pure returns (uint256) {
        return (amount * bps) / 10_000;
    }

    function testTransferInBondingCurvePhase() public {
        address userA = makeAddr("userA");
        address userB = makeAddr("userB");
        vm.deal(userA, 1 ether);
        vm.startPrank(userA);
        _token.buyWithIP{value: 1 ether}(userA, 0, MarketType.BONDING_CURVE);
        vm.stopPrank();

        // should be able to transfer to userB
        uint256 userABalanceBefore = _token.balanceOf(userA);
        vm.prank(userA);
        _token.transfer(userB, userABalanceBefore);
        assertEq(_token.balanceOf(userB), userABalanceBefore);
        assertEq(_token.balanceOf(userA), 0);

        // should revert if transfer to pool
        vm.startPrank(userB);
        uint256 balanceOfB = _token.balanceOf(userB);
        address pool = IUniswapV2Factory(PIPERX_V2_FACTORY).getPair(address(_token), address(WRAPPER_IP));
        vm.expectRevert(abi.encodeWithSelector(SpotlightToken.ForbiddenToSwapBeforeGraduation.selector));
        _token.transfer(pool, balanceOfB);

        // should revert if transfer to factory
        vm.expectRevert(abi.encodeWithSelector(SpotlightToken.ForbiddenToSwapBeforeGraduation.selector));
        _token.transfer(PIPERX_V2_FACTORY, balanceOfB);

        // should revert if transfer to router
        vm.expectRevert(abi.encodeWithSelector(SpotlightToken.ForbiddenToSwapBeforeGraduation.selector));
        _token.transfer(PIPERX_V2_ROUTER, balanceOfB);

        vm.stopPrank();
    }
}
