// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {InitializableERC20} from "./InitializableERC20.sol";
import {ISpotlightToken} from "./ISpotlightToken.sol";
import {SpotlightTokenStorage} from "./SpotlightTokenStorage.sol";
import {BeaconProxyStorage} from "../beacon-proxy/BeaconProxyStorage.sol";
import {ISpotlightBondingCurve} from "../spotlight-bonding-curve/ISpotlightBondingCurve.sol";

contract SpotlightToken is BeaconProxyStorage, InitializableERC20, SpotlightTokenStorage, ISpotlightToken {
    constructor() InitializableERC20() {}

    modifier needInitialized() {
        _checkIsInitialized();
        _;
    }

    modifier onlyOwner() {
        _checkIsOwner();
        _;
    }

    /*
     * @dev See {ISpotlightToken-initialize}.
     */
    function initialize(
        address owner_,
        address tokenCreator_,
        address bondingCurve_,
        address baseToken_,
        address protocolFeeRecipient_,
        string memory tokenName_,
        string memory tokenSymbol_
    ) external {
        _owner = owner_;
        _tokenCreator = tokenCreator_;
        _protocolFeeRecipient = protocolFeeRecipient_;
        _bondingCurve = bondingCurve_;
        _baseToken = baseToken_;
        _tokenName = tokenName_;
        _tokenSymbol = tokenSymbol_;

        _isInitialized = true;
    }

    /*
     * @dev See {ISpotlightToken-isInitialized}.
     */
    function isInitialized() public view needInitialized returns (bool) {
        return _isInitialized;
    }

    /*
     * @dev See {ISpotlightToken-owner}.
     */
    function owner() public view needInitialized returns (address) {
        return _owner;
    }

    /*
     * @dev See {ISpotlightToken-tokenCreator}.
     */
    function tokenCreator() public view needInitialized returns (address) {
        return _tokenCreator;
    }

    /*
     * @dev See {ISpotlightToken-baseToken}.
     */
    function protocolFeeRecipient() public view needInitialized returns (address) {
        return _protocolFeeRecipient;
    }

    /*
     * @dev See {ISpotlightToken-setProtocolFeeRecipient}.
     */
    function setProtocolFeeRecipient(address newRecipient) external needInitialized onlyOwner {
        _protocolFeeRecipient = newRecipient;
    }

    /*
     * @dev See {ISpotlightToken-bondingCurve}.
     */
    function bondingCurve() public view returns (address) {
        return _bondingCurve;
    }

    /*
     * @dev See {ISpotlightToken-setBondingCurve}.
     */
    function buyWithUSDC(uint256 usdcAmount, address recipient, uint256 minTokenOut) external needInitialized {
        uint256 usdcIn;
        uint256 tokenOut;
        uint256 tradingFee;

        tradingFee = (usdcAmount * PROTOCOL_TRADING_FEE_PCT) / 100;
        uint256 usdcOrderSize = usdcAmount - tradingFee;

        if (usdcOrderSize < MIN_USDC_ORDER_SIZE) {
            revert("SpotlightToken: Min order size not met");
        }

        uint256 tokenOutQuote = getUSDCBuyQuote(usdcOrderSize);

        if (tokenOutQuote < minTokenOut) {
            revert("SpotlightToken: Slippage limit exceeded");
        }

        uint256 maxRemainingToken = BONDING_CURVE_SUPPLY - totalSupply();
        if (!(maxRemainingToken > 0)) {
            revert("SpotlightToken: Bonding curve max supply reached");
        }

        if (tokenOutQuote > maxRemainingToken) {
            usdcIn = getTokenBuyQuote(maxRemainingToken);
            tokenOut = maxRemainingToken;
            tradingFee = (usdcIn * PROTOCOL_TRADING_FEE_PCT) / 100;
        } else {
            usdcIn = usdcOrderSize;
            tokenOut = tokenOutQuote;
        }

        _buy(msg.sender, recipient, usdcIn, tokenOut, tradingFee);
    }

    /*
     * @dev See {ISpotlightToken-buyToken}.
     */
    function buyToken(uint256 tokenAmount, address recipient, uint256 maxUSDCIn) external needInitialized {
        if (getTokenBuyQuoteWithFee(tokenAmount) > maxUSDCIn) {
            revert("SpotlightToken: Slippage limit exceeded");
        }

        uint256 usdcIn;
        uint256 tokenOut;
        uint256 tradingFee;

        uint256 maxRemainingToken = BONDING_CURVE_SUPPLY - totalSupply();
        if (!(maxRemainingToken > 0)) {
            revert("SpotlightToken: Bonding curve max supply reached");
        }

        if (tokenAmount > maxRemainingToken) {
            tokenOut = maxRemainingToken;
        } else {
            tokenOut = tokenAmount;
        }

        usdcIn = getTokenBuyQuote(tokenOut);
        if (usdcIn < MIN_USDC_ORDER_SIZE) {
            revert("SpotlightToken: Min order size not met");
        }
        tradingFee = (usdcIn * PROTOCOL_TRADING_FEE_PCT) / 100;

        _buy(msg.sender, recipient, usdcIn, tokenOut, tradingFee);
    }

    /*
     * @dev See {ISpotlightToken-sellToken}.
     */
    function sellToken(uint256 tokenAmount, address recipient, uint256 minUSDCOut) external needInitialized {
        if (tokenAmount > balanceOf(msg.sender)) {
            revert("SpotlightToken: Insufficient balance");
        }

        uint256 tokenIn = tokenAmount;
        uint256 usdcOut;
        uint256 tradingFee;

        uint256 usdcOutQuote = getTokenSellQuote(tokenIn);
        if (usdcOutQuote < MIN_USDC_ORDER_SIZE) {
            revert("SpotlightToken: Min order size not met");
        }
        tradingFee = (usdcOutQuote * PROTOCOL_TRADING_FEE_PCT) / 100;
        usdcOut = usdcOutQuote - tradingFee;
        if (usdcOut < minUSDCOut) {
            revert("SpotlightToken: Slippage limit exceeded");
        }

        _sell(msg.sender, recipient, usdcOut, tokenIn, tradingFee);
    }

    /*
     * @dev See {ISpotlightToken-getUSDCBuyQuote}.
     */
    function getUSDCBuyQuote(uint256 usdcOrderSize) public view needInitialized returns (uint256 tokensOut) {
        tokensOut = ISpotlightBondingCurve(_bondingCurve).getBaseTokenBuyQuote(totalSupply(), usdcOrderSize);
    }

    /*
     * @dev See {ISpotlightToken-getTokenBuyQuote}.
     */
    function getTokenBuyQuote(uint256 tokenOrderSize) public view needInitialized returns (uint256 usdcIn) {
        usdcIn = ISpotlightBondingCurve(_bondingCurve).getTargetTokenBuyQuote(totalSupply(), tokenOrderSize);
    }

    /*
     * @dev See {ISpotlightToken-getTokenSellQuote}.
     */
    function getTokenSellQuote(uint256 tokenOrderSize) public view needInitialized returns (uint256 usdcOut) {
        usdcOut = ISpotlightBondingCurve(_bondingCurve).getTargetTokenSellQuote(totalSupply(), tokenOrderSize);
    }

    /*
     * @dev See {ISpotlightToken-getUSDCBuyQuoteWithFee}.
     */
    function getUSDCBuyQuoteWithFee(uint256 usdcOrderSize) public view needInitialized returns (uint256 tokensOut) {
        uint256 tradingFee = (usdcOrderSize * PROTOCOL_TRADING_FEE_PCT) / 100;
        uint256 realUSDCOrderSize = usdcOrderSize - tradingFee;
        tokensOut = ISpotlightBondingCurve(_bondingCurve).getBaseTokenBuyQuote(totalSupply(), realUSDCOrderSize);
    }

    /*
     * @dev See {ISpotlightToken-getTokenBuyQuoteWithFee}.
     */
    function getTokenBuyQuoteWithFee(uint256 tokenOrderSize) public view needInitialized returns (uint256 usdcIn) {
        uint256 usdcNeeded = ISpotlightBondingCurve(_bondingCurve).getTargetTokenBuyQuote(totalSupply(), tokenOrderSize);
        uint256 tradingFee = (usdcNeeded * PROTOCOL_TRADING_FEE_PCT) / 100;
        usdcIn = usdcNeeded + tradingFee;
    }

    /*
     * @dev See {ISpotlightToken-getTokenSellQuoteWithFee}.
     */
    function getTokenSellQuoteWithFee(uint256 tokenOrderSize) public view needInitialized returns (uint256 usdcOut) {
        uint256 usdcFromTrading =
            ISpotlightBondingCurve(_bondingCurve).getTargetTokenSellQuote(totalSupply(), tokenOrderSize);
        uint256 tradingFee = (usdcFromTrading * PROTOCOL_TRADING_FEE_PCT) / 100;
        usdcOut = usdcFromTrading - tradingFee;
    }

    // @dev Private functions
    function _checkIsOwner() internal view {
        require(msg.sender == _owner, "SpotlightToken: Not owner");
    }

    function _checkIsInitialized() internal view {
        require(_isInitialized, "SpotlightToken: Not initialized");
    }

    function _buy(address buyer, address recipient, uint256 usdcIn, uint256 tokenOut, uint256 tradingFee) internal {
        IERC20(_baseToken).transferFrom(buyer, address(this), usdcIn);
        IERC20(_baseToken).transferFrom(buyer, _protocolFeeRecipient, tradingFee);
        _mint(recipient, tokenOut);

        emit SpotlightTokenBought(buyer, recipient, usdcIn + tradingFee, tradingFee, usdcIn, tokenOut, totalSupply());
    }

    function _sell(address seller, address recipient, uint256 usdcOut, uint256 tokenIn, uint256 tradingFee) internal {
        _burn(seller, tokenIn);
        IERC20(_baseToken).transfer(_protocolFeeRecipient, tradingFee);
        IERC20(_baseToken).transfer(recipient, usdcOut);

        emit SpotlightTokenSold(seller, recipient, usdcOut - tradingFee, tradingFee, usdcOut, tokenIn, totalSupply());
    }
}
