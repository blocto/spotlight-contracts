// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {InitializableERC20} from "./InitializableERC20.sol";
import {ISpotlightToken} from "./ISpotlightToken.sol";
import {SpotlightTokenStorage} from "./SpotlightTokenStorage.sol";
import {ISpotlightBondingCurve} from "../spotlight-bonding-curve/ISpotlightBondingCurve.sol";

contract SpotlightToken is Ownable, InitializableERC20, ISpotlightToken, SpotlightTokenStorage {
    constructor() InitializableERC20() Ownable(msg.sender) {}

    function initialize(
        address tokenCreator_,
        address bondingCurve_,
        address baseToken_,
        address protocolFeeRecipient_,
        string memory tokenName_,
        string memory tokenSymbol_
    ) external {
        _tokenCreator = tokenCreator_;
        _protocolFeeRecipient = protocolFeeRecipient_;
        _bondingCurve = bondingCurve_;
        _baseToken = baseToken_;
        _tokenName = tokenName_;
        _tokenSymbol = tokenSymbol_;

        _isInitialized = true;
    }

    modifier needInitialized() {
        _checkIsInitialized();
        _;
    }

    function isInitialized() public view returns (bool) {
        return _isInitialized;
    }

    function tokenCreator() public view returns (address) {
        return _tokenCreator;
    }

    function protocolFeeRecipient() public view returns (address) {
        return _protocolFeeRecipient;
    }

    function setProtocolFeeRecipient(address newRecipient) external onlyOwner {
        _protocolFeeRecipient = newRecipient;
    }

    function bondingCurve() public view returns (address) {
        return _bondingCurve;
    }

    function buyWithUSDC(uint256 usdcAmount, address recipient, uint256 minTokenOut) external needInitialized {
        uint256 usdcIn;
        uint256 tokenOut;
        uint256 tradingFee;

        tradingFee = (usdcAmount * PROTOCOL_TRADING_FEE_PCT) / 100;
        uint256 usdcOrderSize = usdcAmount - tradingFee;

        if (usdcOrderSize < MIN_USDC_ORDER_SIZE) {
            revert("SpotlightToken: Min order size not met");
        }

        uint256 quotedTokenOut = getUSDCBuyQuote(usdcOrderSize);

        if (quotedTokenOut < minTokenOut) {
            revert("SpotlightToken: Slippage limit exceeded");
        }

        uint256 maxRemainingToken = BONDIGN_CURVE_SUPPLY - totalSupply();
        if (quotedTokenOut > maxRemainingToken) {
            usdcIn = getTokenBuyQuote(maxRemainingToken);
            tokenOut = maxRemainingToken;
            tradingFee = (usdcIn * PROTOCOL_TRADING_FEE_PCT) / 100;
        } else {
            usdcIn = usdcOrderSize;
            tokenOut = quotedTokenOut;
        }

        IERC20(_baseToken).transferFrom(msg.sender, address(this), usdcIn);
        IERC20(_baseToken).transferFrom(msg.sender, _protocolFeeRecipient, tradingFee);
        _mint(recipient, tokenOut);
    }

    function buyToken(uint256 tokenAmount, address recipient, uint256 maxUSDCIn) external needInitialized {
        uint256 usdcIn;
        uint256 tokenOut;
        uint256 tradingFee;

        uint256 maxRemainingToken = BONDIGN_CURVE_SUPPLY - totalSupply();
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
        if ((usdcIn + tradingFee) > maxUSDCIn) {
            revert("SpotlightToken: Max USDC in exceeded");
        }

        IERC20(_baseToken).transferFrom(msg.sender, address(this), usdcIn);
        IERC20(_baseToken).transferFrom(msg.sender, _protocolFeeRecipient, tradingFee);
        _mint(recipient, tokenOut);
    }

    function sellToken(uint256 tokenAmount, address recipient, uint256 minUSDCOut) external needInitialized {
        if (tokenAmount > balanceOf(msg.sender)) {
            revert("SpotlightToken: Insufficient balance");
        }

        uint256 tokenIn = tokenAmount;
        uint256 usdcOut;
        uint256 tradingFee;

        uint256 quotedUSDCOut = getTokenSellQuote(tokenIn);
        if (quotedUSDCOut < MIN_USDC_ORDER_SIZE) {
            revert("SpotlightToken: Min order size not met");
        }
        tradingFee = (usdcOut * PROTOCOL_TRADING_FEE_PCT) / 100;
        usdcOut = quotedUSDCOut - tradingFee;
        if (usdcOut < minUSDCOut) {
            revert("SpotlightToken: Slippage limit exceeded");
        }

        _burn(msg.sender, tokenIn);
        IERC20(_baseToken).transfer(_protocolFeeRecipient, tradingFee);
        IERC20(_baseToken).transfer(recipient, usdcOut);
    }

    function getUSDCBuyQuote(uint256 usdcOrderSize) public view needInitialized returns (uint256 tokensOut) {
        tokensOut = ISpotlightBondingCurve(_bondingCurve).getBaseTokenBuyQuote(totalSupply(), usdcOrderSize);
    }

    function getTokenBuyQuote(uint256 tokenOrderSize) public view needInitialized returns (uint256 usdcIn) {
        usdcIn = ISpotlightBondingCurve(_bondingCurve).getTargetTokenBuyQuote(totalSupply(), tokenOrderSize);
    }

    function getTokenSellQuote(uint256 tokenOrderSize) public view needInitialized returns (uint256 usdcOut) {
        usdcOut = ISpotlightBondingCurve(_bondingCurve).getTargetTokenSellQuote(totalSupply(), tokenOrderSize);
    }

    function getUSDCBuyQuoteWithFee(uint256 usdcOrderSize) public view needInitialized returns (uint256 tokensOut) {
        uint256 realUSDCOrderSize = (usdcOrderSize * (100 - PROTOCOL_TRADING_FEE_PCT)) / 100;
        tokensOut = ISpotlightBondingCurve(_bondingCurve).getBaseTokenBuyQuote(totalSupply(), realUSDCOrderSize);
    }

    function getTokenBuyQuoteWithFee(uint256 tokenOrderSize) public view needInitialized returns (uint256 usdcIn) {
        uint256 usdcNeeded = ISpotlightBondingCurve(_bondingCurve).getTargetTokenBuyQuote(totalSupply(), tokenOrderSize);
        usdcIn = (usdcNeeded * 100) / (100 - PROTOCOL_TRADING_FEE_PCT);
    }

    function getTokenSellQuoteWithFee(uint256 tokenOrderSize) public view needInitialized returns (uint256 usdcOut) {
        uint256 usdcFromTrading =
            ISpotlightBondingCurve(_bondingCurve).getTargetTokenSellQuote(totalSupply(), tokenOrderSize);
        usdcOut = (usdcFromTrading * (100 - PROTOCOL_TRADING_FEE_PCT)) / 100;
    }

    function _checkIsInitialized() internal view {
        require(_isInitialized, "SpotlightToken: Not initialized");
    }
}
