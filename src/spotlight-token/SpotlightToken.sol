// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {InitializableERC20} from "./InitializableERC20.sol";
import {ISpotlightToken} from "./ISpotlightToken.sol";
import {SpotlightTokenStorage} from "./SpotlightTokenStorage.sol";
import {BeaconProxyStorage} from "../beacon-proxy/BeaconProxyStorage.sol";
import {ISpotlightBondingCurve} from "../spotlight-bonding-curve/ISpotlightBondingCurve.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";
import {MarketType, MarketState} from "./ISpotlightToken.sol";

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

    error SlippageBoundsExceeded();
    error EthTransferFailed();
    error InvalidMarketType();
    error InsufficientLiquidity();
    error AddressZero();
    error EthAmountTooSmall();

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
        string memory tokenSymbol_,
        address piperXRouter_,
        address piperXFactory_
    ) external {
        if (isInitialized()) {
            revert("SpotlightToken: Already initialized");
        }

        _owner = owner_;
        _tokenCreator = tokenCreator_;
        _protocolFeeRecipient = protocolFeeRecipient_;
        _bondingCurve = bondingCurve_;
        _baseToken = baseToken_;
        _tokenName = tokenName_;
        _tokenSymbol = tokenSymbol_;

        _isInitialized = true;
        _marketType = MarketType.BONDING_CURVE;
        _piperXRouter = piperXRouter_;
        _piperXFactory = piperXFactory_;
    }

    /*
     * @dev See {ISpotlightToken-isInitialized}.
     */
    function isInitialized() public view returns (bool) {
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
     * @dev See {ISpotlightToken-state}.
     */
    function state() external view returns (MarketState memory) {
        return MarketState({
            marketType: _marketType,
            marketAddress: _marketType == MarketType.BONDING_CURVE ? address(this) : _pairAddress
        });
    }

    /*
     * @dev See {ISpotlightToken-setBondingCurve}.
     */
    function buyWithIP(address recipient, uint256 minTokenOut, MarketType expectedMarketType)
        public
        payable
        needInitialized
    {
        if (_marketType != expectedMarketType) revert InvalidMarketType();
        if (msg.value < MIN_IP_ORDER_SIZE) revert EthAmountTooSmall();
        if (recipient == address(0)) revert AddressZero();

        uint256 totalCost;
        uint256 trueOrderSize;
        uint256 fee;
        uint256 refund;

        if (_marketType == MarketType.PIPERX_POOL) {
            totalCost = msg.value;
            IWETH(_baseToken).deposit{value: totalCost}();
            IERC20(_baseToken).approve(_piperXRouter, totalCost);

            address[] memory path = new address[](2);
            path[0] = _baseToken;
            path[1] = address(this);

            uint256[] memory amounts = IUniswapV2Router02(_piperXRouter).swapExactTokensForTokens(
                totalCost, minTokenOut, path, recipient, block.timestamp
            );

            trueOrderSize = amounts[1];
        }

        if (_marketType == MarketType.BONDING_CURVE) {
            bool shouldGraduateMarket;
            (totalCost, trueOrderSize, fee, refund, shouldGraduateMarket) = _validateBondingCurveBuy(minTokenOut);

            _mint(recipient, trueOrderSize);
            _disperseFees(fee, msg.sender);
            if (refund > 0) {
                (bool success,) = recipient.call{value: refund}("");
                if (!success) revert EthTransferFailed();
            }

            emit SpotlightTokenBought(
                msg.sender, recipient, totalCost, fee, totalCost - fee, trueOrderSize, totalSupply()
            );

            if (shouldGraduateMarket) {
                _graduateMarket();
            }
        }
    }

    /*
     * @dev See {ISpotlightToken-buyToken}.
     */
    function buyToken(uint256 tokenAmount, address recipient, MarketType expectedMarketType)
        external
        payable
        needInitialized
    {
        if (_marketType != expectedMarketType) revert InvalidMarketType();
        if (msg.value < MIN_IP_ORDER_SIZE) revert EthAmountTooSmall();
        if (recipient == address(0)) revert AddressZero();

        uint256 totalCost;
        uint256 trueOrderSize;
        uint256 fee;
        uint256 refund;

        if (_marketType == MarketType.PIPERX_POOL) {
            address[] memory path = new address[](2);
            path[0] = _baseToken;
            path[1] = address(this);

            uint256[] memory amountIns = IUniswapV2Router02(_piperXRouter).getAmountsIn(tokenAmount, path);
            uint256 amountIn = amountIns[0];

            IWETH(_baseToken).deposit{value: amountIn}();
            IERC20(_baseToken).approve(_piperXRouter, amountIn);

            uint256[] memory amounts = IUniswapV2Router02(_piperXRouter).swapTokensForExactTokens(
                tokenAmount, amountIn, path, recipient, block.timestamp
            );

            trueOrderSize = amounts[1];
        }

        if (_marketType == MarketType.BONDING_CURVE) {
            bool shouldGraduateMarket;
            (totalCost, trueOrderSize, fee, refund, shouldGraduateMarket) = _validateBondingCurveBuyToken(tokenAmount);

            _mint(recipient, trueOrderSize);
            _disperseFees(fee, msg.sender);

            if (refund > 0) {
                (bool success,) = recipient.call{value: refund}("");
                if (!success) revert EthTransferFailed();
            }

            emit SpotlightTokenBought(
                msg.sender, recipient, totalCost, fee, totalCost - fee, trueOrderSize, totalSupply()
            );

            if (shouldGraduateMarket) {
                _graduateMarket();
            }
        }
    }

    /*
     * @dev See {ISpotlightToken-sellToken}.
     */
    function sellToken(uint256 tokenAmount, address recipient, uint256 minIPOut, MarketType expectedMarketType)
        external
        needInitialized
    {
        if (_marketType != expectedMarketType) revert InvalidMarketType();
        if (recipient == address(0)) revert AddressZero();
        if (tokenAmount > balanceOf(msg.sender)) {
            revert InsufficientLiquidity();
        }

        uint256 truePayoutSize;
        uint256 payoutAfterFee;
        if (_marketType == MarketType.PIPERX_POOL) {
            truePayoutSize = _handleUniswapSell(tokenAmount, minIPOut);
            payoutAfterFee = truePayoutSize;
        }

        if (_marketType == MarketType.BONDING_CURVE) {
            truePayoutSize = _handleBondingCurveSell(tokenAmount, minIPOut);
            uint256 fee = _calculateFee(truePayoutSize, TOTAL_FEE_BPS);
            payoutAfterFee = truePayoutSize - fee;
            _disperseFees(fee, msg.sender);

            emit SpotlightTokenSold(
                msg.sender, recipient, payoutAfterFee, fee, truePayoutSize, tokenAmount, totalSupply()
            );
        }

        (bool success,) = recipient.call{value: payoutAfterFee}("");
        if (!success) revert EthTransferFailed();
    }

    receive() external payable {
        if (msg.sender == _baseToken) {
            return;
        }

        buyWithIP(msg.sender, 0, _marketType);
    }

    /*
     * @dev See {ISpotlightToken-getIPBuyQuote}.
     */
    function getIPBuyQuote(uint256 ipOrderSize) public view needInitialized returns (uint256 tokensOut) {
        if (_marketType == MarketType.PIPERX_POOL) revert InvalidMarketType();
        tokensOut = ISpotlightBondingCurve(_bondingCurve).getBaseTokenBuyQuote(totalSupply(), ipOrderSize);
    }

    /*
     * @dev See {ISpotlightToken-getTokenBuyQuote}.
     */
    function getTokenBuyQuote(uint256 tokenOrderSize) public view needInitialized returns (uint256 ipIn) {
        if (_marketType == MarketType.PIPERX_POOL) revert InvalidMarketType();
        ipIn = ISpotlightBondingCurve(_bondingCurve).getTargetTokenBuyQuote(totalSupply(), tokenOrderSize);
    }

    /*
     * @dev See {ISpotlightToken-getTokenSellQuote}.
     */
    function getTokenSellQuote(uint256 tokenOrderSize) public view needInitialized returns (uint256 ipOut) {
        if (_marketType == MarketType.PIPERX_POOL) revert InvalidMarketType();
        ipOut = ISpotlightBondingCurve(_bondingCurve).getTargetTokenSellQuote(totalSupply(), tokenOrderSize);
    }

    /*
     * @dev See {ISpotlightToken-getIPBuyQuoteWithFee}.
     */
    function getIPBuyQuoteWithFee(uint256 ipOrderSize) public view needInitialized returns (uint256 tokensOut) {
        if (_marketType == MarketType.PIPERX_POOL) revert InvalidMarketType();

        uint256 tradingFee = _calculateFee(ipOrderSize, TOTAL_FEE_BPS);
        uint256 realIPOrderSize = ipOrderSize - tradingFee;
        tokensOut = ISpotlightBondingCurve(_bondingCurve).getBaseTokenBuyQuote(totalSupply(), realIPOrderSize);
    }

    /*
     * @dev See {ISpotlightToken-getTokenBuyQuoteWithFee}.
     */
    function getTokenBuyQuoteWithFee(uint256 tokenOrderSize) public view needInitialized returns (uint256 ipIn) {
        if (_marketType == MarketType.PIPERX_POOL) revert InvalidMarketType();

        uint256 ipNeeded = ISpotlightBondingCurve(_bondingCurve).getTargetTokenBuyQuote(totalSupply(), tokenOrderSize);
        uint256 tradingFee = _calculateFee(ipNeeded, PROTOCOL_TRADING_FEE_PCT);

        ipIn = ipNeeded + tradingFee;
    }

    /*
     * @dev See {ISpotlightToken-getTokenSellQuoteWithFee}.
     */
    function getTokenSellQuoteWithFee(uint256 tokenOrderSize) public view needInitialized returns (uint256 ipOut) {
        if (_marketType == MarketType.PIPERX_POOL) revert InvalidMarketType();

        uint256 ipFromTrading =
            ISpotlightBondingCurve(_bondingCurve).getTargetTokenSellQuote(totalSupply(), tokenOrderSize);
        uint256 tradingFee = _calculateFee(ipFromTrading, PROTOCOL_TRADING_FEE_PCT);
        ipOut = ipFromTrading - tradingFee;
    }

    // @dev Private functions
    function _checkIsOwner() internal view {
        require(msg.sender == _owner, "SpotlightToken: Not owner");
    }

    function _checkIsInitialized() internal view {
        require(_isInitialized, "SpotlightToken: Not initialized");
    }

    function _handleBondingCurveSell(uint256 tokensToSell, uint256 minPayoutSize) private returns (uint256) {
        uint256 payout = ISpotlightBondingCurve(_bondingCurve).getTargetTokenSellQuote(totalSupply(), tokensToSell);

        if (payout < minPayoutSize) revert SlippageBoundsExceeded();
        if (payout < MIN_IP_ORDER_SIZE) revert EthAmountTooSmall();

        _burn(msg.sender, tokensToSell);

        return payout;
    }

    function _handleUniswapSell(uint256 tokensToSell, uint256 minPayoutSize) private returns (uint256) {
        transfer(address(this), tokensToSell);
        this.approve(address(_piperXRouter), tokensToSell);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _baseToken;

        uint256[] memory amounts = IUniswapV2Router02(_piperXRouter).swapExactTokensForTokens(
            tokensToSell, minPayoutSize, path, address(this), block.timestamp
        );

        uint256 payout = amounts[1];
        IWETH(_baseToken).withdraw(payout);

        return payout;
    }

    function _validateBondingCurveBuyToken(uint256 tokenAmount)
        internal
        returns (uint256 totalCost, uint256 trueOrderSize, uint256 fee, uint256 refund, bool startMarket)
    {
        uint256 ipIn = getTokenBuyQuote(tokenAmount);
        fee = _calculateFee(ipIn, TOTAL_FEE_BPS);

        totalCost = ipIn + fee;
        
        if (totalCost > msg.value) revert EthAmountTooSmall();

        uint256 maxRemainingTokens = BONDING_CURVE_SUPPLY - totalSupply();

        trueOrderSize = tokenAmount;
        if (trueOrderSize == maxRemainingTokens) {
            startMarket = true;
        }

        if (trueOrderSize > maxRemainingTokens) {
            trueOrderSize = maxRemainingTokens;
            uint256 ethNeeded = getTokenBuyQuote(trueOrderSize);
            fee = _calculateFee(ethNeeded, TOTAL_FEE_BPS);
            totalCost = ethNeeded + fee;
            if (msg.value > totalCost) {
                refund = msg.value - totalCost;
            }
            startMarket = true;
        }
    }

    function _validateBondingCurveBuy(uint256 minOrderSize)
        internal
        returns (uint256 totalCost, uint256 trueOrderSize, uint256 fee, uint256 refund, bool startMarket)
    {
        totalCost = msg.value;
        fee = _calculateFee(totalCost, TOTAL_FEE_BPS);
        uint256 remainingEth = totalCost - fee;

        trueOrderSize = getIPBuyQuote(remainingEth);

        if (trueOrderSize < minOrderSize) revert SlippageBoundsExceeded();
        uint256 maxRemainingTokens = BONDING_CURVE_SUPPLY - totalSupply();

        if (trueOrderSize == maxRemainingTokens) {
            startMarket = true;
        }

        if (trueOrderSize > maxRemainingTokens) {
            trueOrderSize = maxRemainingTokens;
            uint256 ethNeeded = getTokenBuyQuote(trueOrderSize);
            fee = _calculateFee(ethNeeded, TOTAL_FEE_BPS);
            totalCost = ethNeeded + fee;
            if (msg.value > totalCost) {
                refund = msg.value - totalCost;
            }
            startMarket = true;
        }
    }

    function _calculateFee(uint256 amount, uint256 bps) internal pure returns (uint256) {
        return (amount * bps) / 100;
    }

    function _disperseFees(uint256 _fee, address _orderReferrer) internal {
        (bool success,) = _protocolFeeRecipient.call{value: _fee}("");
        if (!success) revert EthTransferFailed();
    }

    function _graduateMarket() internal {
        _marketType = MarketType.PIPERX_POOL;

        uint256 ethLiquidity = address(this).balance;
        IWETH(_baseToken).deposit{value: ethLiquidity}();
        _mint(address(this), SECONDARY_MARKET_SUPPLY);

        IERC20(_baseToken).approve(address(_piperXRouter), ethLiquidity);
        IERC20(address(this)).approve(address(_piperXRouter), SECONDARY_MARKET_SUPPLY);

        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = IUniswapV2Router02(_piperXRouter).addLiquidity(
            address(this), _baseToken, SECONDARY_MARKET_SUPPLY, ethLiquidity, 0, 0, address(this), block.timestamp
        );

        _pairAddress = IUniswapV2Factory(_piperXFactory).getPair(address(this), _baseToken);

        emit SpotlightTokenGraduated(address(this), _pairAddress, amountETH, amountToken, liquidity, _marketType);
    }
}
