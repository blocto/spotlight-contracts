// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ISpotlightToken} from "./ISpotlightToken.sol";
import {SpotlightTokenStorage} from "./SpotlightTokenStorage.sol";
import {ISpotlightBondingCurve} from "../spotlight-bonding-curve/ISpotlightBondingCurve.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";
import {MarketType, MarketState} from "./ISpotlightToken.sol";
import {ISpotlightProtocolRewards} from "../spotlight-protocol-rewards/ISpotlightProtocolRewards.sol";

contract SpotlightToken is ERC20Upgradeable, ReentrancyGuardTransient, SpotlightTokenStorage, ISpotlightToken {
    constructor() {
        _disableInitializers();
    }

    modifier needInitialized() {
        _checkIsInitialized();
        _;
    }

    error SlippageBoundsExceeded();
    error IPTransferFailed();
    error InvalidMarketType();
    error InsufficientLiquidity();
    error AddressZero();
    error IPAmountTooSmall();

    /*
     * @dev See {ISpotlightToken-initialize}.
     */
    function initialize(
        string memory tokenName_,
        string memory tokenSymbol_,
        address tokenCreator_,
        address bondingCurve_,
        address protocolFeeRecipient_,
        address ipAccount_,
        address rewardsVault_,
        address piperXRouter_,
        address piperXFactory_
    ) external initializer {
        __ERC20_init(tokenName_, tokenSymbol_);
        _tokenCreator = tokenCreator_;
        _bondingCurve = bondingCurve_;
        _protocolFeeRecipient = protocolFeeRecipient_;
        _ipAccount = ipAccount_;
        _rewardsVault = rewardsVault_;
        _piperXRouter = piperXRouter_;
        _piperXFactory = piperXFactory_;

        _marketType = MarketType.BONDING_CURVE;
    }

    /**
     * @dev Returns `true` if the contract is initialized.
     */
    function isInitialized() public view returns (bool) {
        return _getInitializedVersion() == 1;
    }

    /*
     * @dev See {ISpotlightToken-tokenCreator}.
     */
    function tokenCreator() public view returns (address) {
        return _tokenCreator;
    }

    /*
     * @dev See {ISpotlightToken-bondingCurve}.
     */
    function bondingCurve() public view returns (address) {
        return _bondingCurve;
    }

    /*
     * @dev See {ISpotlightToken-protocolFeeRecipient}.
     */
    function protocolFeeRecipient() public view returns (address) {
        return _protocolFeeRecipient;
    }

    /*
     * @dev See {ISpotlightToken-rewardsVault}.
     */
    function rewardsVault() public view returns (address) {
        return _rewardsVault;
    }

    /*
     * @dev See {ISpotlightToken-piperXRouter}.
     */
    function piperXRouter() public view returns (address) {
        return _piperXRouter;
    }

    /*
     * @dev See {ISpotlightToken-piperXFactory}.
     */
    function piperXFactory() public view returns (address) {
        return _piperXFactory;
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
     * @dev See {ISpotlightToken-buyWithIP}.
     */
    function buyWithIP(address recipient, uint256 minTokenOut, MarketType expectedMarketType)
        public
        payable
        needInitialized
        nonReentrant
    {
        if (_marketType != expectedMarketType) revert InvalidMarketType();
        if (msg.value < MIN_IP_ORDER_SIZE) revert IPAmountTooSmall();
        if (recipient == address(0)) revert AddressZero();

        uint256 totalCost;
        uint256 trueOrderSize;
        uint256 fee;
        uint256 refund;

        if (_marketType == MarketType.PIPERX_POOL) {
            totalCost = msg.value;

            address[] memory path = new address[](2);
            path[0] = IUniswapV2Router02(_piperXRouter).WETH();
            path[1] = address(this);

            uint256[] memory amounts = IUniswapV2Router02(_piperXRouter).swapExactETHForTokens{value: totalCost}(
                minTokenOut, path, recipient, block.timestamp
            );

            trueOrderSize = amounts[1];
        } else if (_marketType == MarketType.BONDING_CURVE) {
            bool shouldGraduateMarket;
            (totalCost, trueOrderSize, fee, refund, shouldGraduateMarket) = _validateBondingCurveBuy(minTokenOut);

            _mint(recipient, trueOrderSize);
            _disperseFees(fee);
            if (refund > 0) {
                (bool success,) = recipient.call{value: refund}("");
                if (!success) revert IPTransferFailed();
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
        nonReentrant
    {
        if (_marketType != expectedMarketType) revert InvalidMarketType();
        if (msg.value < MIN_IP_ORDER_SIZE) revert IPAmountTooSmall();
        if (recipient == address(0)) revert AddressZero();

        uint256 totalCost;
        uint256 trueOrderSize;
        uint256 fee;
        uint256 refund;

        if (_marketType == MarketType.PIPERX_POOL) {
            address[] memory path = new address[](2);
            path[0] = IUniswapV2Router02(_piperXRouter).WETH();
            path[1] = address(this);

            uint256[] memory amountIns = IUniswapV2Router02(_piperXRouter).getAmountsIn(tokenAmount, path);
            uint256 amountIn = amountIns[0];

            uint256[] memory amounts = IUniswapV2Router02(_piperXRouter).swapETHForExactTokens{value: amountIn}(
                tokenAmount, path, recipient, block.timestamp
            );

            trueOrderSize = amounts[1];
        } else if (_marketType == MarketType.BONDING_CURVE) {
            bool shouldGraduateMarket;
            (totalCost, trueOrderSize, fee, refund, shouldGraduateMarket) = _validateBondingCurveBuyToken(tokenAmount);

            _mint(recipient, trueOrderSize);
            _disperseFees(fee);

            if (refund > 0) {
                (bool success,) = recipient.call{value: refund}("");
                if (!success) revert IPTransferFailed();
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
        nonReentrant
    {
        if (_marketType != expectedMarketType) revert InvalidMarketType();
        if (recipient == address(0)) revert AddressZero();
        if (tokenAmount > balanceOf(msg.sender)) {
            revert InsufficientLiquidity();
        }

        if (_marketType == MarketType.PIPERX_POOL) {
            _handleUniswapSell(tokenAmount, minIPOut, recipient);
        } else if (_marketType == MarketType.BONDING_CURVE) {
            uint256 truePayoutSize;
            uint256 payoutAfterFee;
            truePayoutSize = _handleBondingCurveSell(tokenAmount, minIPOut);
            uint256 fee = _calculateFee(truePayoutSize, TOTAL_FEE_BPS);
            payoutAfterFee = truePayoutSize - fee;
            _disperseFees(fee);

            (bool success,) = recipient.call{value: payoutAfterFee}("");
            if (!success) revert IPTransferFailed();

            emit SpotlightTokenSold(
                msg.sender, recipient, payoutAfterFee, fee, truePayoutSize, tokenAmount, totalSupply()
            );
        }
    }

    receive() external payable {
        if (msg.sender == IUniswapV2Router02(_piperXRouter).WETH()) {
            return;
        }

        buyWithIP(msg.sender, 0, _marketType);
    }

    /*
     * @dev See {ISpotlightToken-getIPBuyQuote}.
     */
    function getIPBuyQuote(uint256 ipOrderSize) public view returns (uint256 tokensOut) {
        if (_marketType == MarketType.PIPERX_POOL) {
            address[] memory path = new address[](2);
            path[0] = IUniswapV2Router02(_piperXRouter).WETH();
            path[1] = address(this);

            uint256[] memory amounts = IUniswapV2Router02(_piperXRouter).getAmountsOut(ipOrderSize, path);
            tokensOut = amounts[1];
        } else if (_marketType == MarketType.BONDING_CURVE) {
            tokensOut = ISpotlightBondingCurve(_bondingCurve).getBaseTokenBuyQuote(totalSupply(), ipOrderSize);
        }
    }

    /*
     * @dev See {ISpotlightToken-getTokenBuyQuote}.
     */
    function getTokenBuyQuote(uint256 tokenOrderSize) public view returns (uint256 ipIn) {
        if (_marketType == MarketType.PIPERX_POOL) {
            address[] memory path = new address[](2);
            path[0] = IUniswapV2Router02(_piperXRouter).WETH();
            path[1] = address(this);

            uint256[] memory amounts = IUniswapV2Router02(_piperXRouter).getAmountsIn(tokenOrderSize, path);
            ipIn = amounts[0];
        } else if (_marketType == MarketType.BONDING_CURVE) {
            ipIn = ISpotlightBondingCurve(_bondingCurve).getTargetTokenBuyQuote(totalSupply(), tokenOrderSize);
        }
    }

    /*
     * @dev See {ISpotlightToken-getTokenSellQuote}.
     */
    function getTokenSellQuote(uint256 tokenOrderSize) public view returns (uint256 ipOut) {
        if (_marketType == MarketType.PIPERX_POOL) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = IUniswapV2Router02(_piperXRouter).WETH();

            uint256[] memory amounts = IUniswapV2Router02(_piperXRouter).getAmountsOut(tokenOrderSize, path);
            ipOut = amounts[1];
        } else if (_marketType == MarketType.BONDING_CURVE) {
            ipOut = ISpotlightBondingCurve(_bondingCurve).getTargetTokenSellQuote(totalSupply(), tokenOrderSize);
        }
    }

    /*
     * @dev See {ISpotlightToken-getIPBuyQuoteWithFee}.
     */
    function getIPBuyQuoteWithFee(uint256 ipOrderSize) public view returns (uint256 tokensOut) {
        if (_marketType == MarketType.PIPERX_POOL) revert InvalidMarketType();

        uint256 tradingFee = _calculateFee(ipOrderSize, TOTAL_FEE_BPS);
        uint256 realIPOrderSize = ipOrderSize - tradingFee;
        tokensOut = ISpotlightBondingCurve(_bondingCurve).getBaseTokenBuyQuote(totalSupply(), realIPOrderSize);
    }

    /*
     * @dev See {ISpotlightToken-getTokenBuyQuoteWithFee}.
     */
    function getTokenBuyQuoteWithFee(uint256 tokenOrderSize) public view returns (uint256 ipIn) {
        if (_marketType == MarketType.PIPERX_POOL) revert InvalidMarketType();

        uint256 ipNeeded = ISpotlightBondingCurve(_bondingCurve).getTargetTokenBuyQuote(totalSupply(), tokenOrderSize);
        uint256 tradingFee = _calculateFee(ipNeeded, TOTAL_FEE_BPS);

        ipIn = ipNeeded + tradingFee;
    }

    /*
     * @dev See {ISpotlightToken-getTokenSellQuoteWithFee}.
     */
    function getTokenSellQuoteWithFee(uint256 tokenOrderSize) public view returns (uint256 ipOut) {
        if (_marketType == MarketType.PIPERX_POOL) revert InvalidMarketType();

        uint256 ipFromTrading =
            ISpotlightBondingCurve(_bondingCurve).getTargetTokenSellQuote(totalSupply(), tokenOrderSize);
        uint256 tradingFee = _calculateFee(ipFromTrading, TOTAL_FEE_BPS);
        ipOut = ipFromTrading - tradingFee;
    }

    function _checkIsInitialized() internal view {
        require(isInitialized(), "SpotlightToken: Not initialized");
    }

    function _handleBondingCurveSell(uint256 tokensToSell, uint256 minPayoutSize) private returns (uint256) {
        uint256 payout = ISpotlightBondingCurve(_bondingCurve).getTargetTokenSellQuote(totalSupply(), tokensToSell);

        if (payout < minPayoutSize) revert SlippageBoundsExceeded();
        if (payout < MIN_IP_ORDER_SIZE) revert IPAmountTooSmall();

        _burn(msg.sender, tokensToSell);

        return payout;
    }

    function _handleUniswapSell(uint256 tokensToSell, uint256 minPayoutSize, address recipient)
        private
        returns (uint256)
    {
        transfer(address(this), tokensToSell);
        this.approve(address(_piperXRouter), tokensToSell);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = IUniswapV2Router02(_piperXRouter).WETH();

        uint256[] memory amounts = IUniswapV2Router02(_piperXRouter).swapExactTokensForETH(
            tokensToSell, minPayoutSize, path, recipient, block.timestamp
        );

        return amounts[1];
    }

    function _validateBondingCurveBuyToken(uint256 tokenAmount)
        internal
        returns (uint256 totalCost, uint256 trueOrderSize, uint256 fee, uint256 refund, bool startMarket)
    {
        uint256 ipIn = getTokenBuyQuote(tokenAmount);
        fee = _calculateFee(ipIn, TOTAL_FEE_BPS);

        totalCost = ipIn + fee;

        if (totalCost > msg.value) revert SlippageBoundsExceeded();

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
        return (amount * bps) / 10_000;
    }

    function _disperseFees(uint256 _fee) internal {
        if (_ipAccount == address(0)) {
            (bool success,) = _protocolFeeRecipient.call{value: _fee}("");
            if (!success) revert IPTransferFailed();
            return;
        }

        uint256 ipAccountFee = _calculateFee(_fee, IP_ACCOUNT_FEE_BPS);
        uint256 protocolFee = _fee - ipAccountFee; // others are protocol fees

        (bool protocolSuccess,) = _protocolFeeRecipient.call{value: protocolFee}("");
        if (!protocolSuccess) revert IPTransferFailed();

        ISpotlightProtocolRewards(_rewardsVault).deposit{value: ipAccountFee}(_ipAccount);
    }

    function _graduateMarket() internal {
        _marketType = MarketType.PIPERX_POOL;

        (bool success,) = _protocolFeeRecipient.call{value: LISTING_FEE}("");
        if (!success) revert IPTransferFailed();

        uint256 ethLiquidity = address(this).balance;

        _mint(address(this), SECONDARY_MARKET_SUPPLY);
        IERC20(address(this)).approve(_piperXRouter, SECONDARY_MARKET_SUPPLY);

        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = IUniswapV2Router02(_piperXRouter).addLiquidityETH{
            value: ethLiquidity
        }(address(this), SECONDARY_MARKET_SUPPLY, SECONDARY_MARKET_SUPPLY, ethLiquidity, address(0), block.timestamp);

        _pairAddress =
            IUniswapV2Factory(_piperXFactory).getPair(address(this), IUniswapV2Router02(_piperXRouter).WETH());

        emit SpotlightTokenGraduated(address(this), _pairAddress, amountETH, amountToken, liquidity, _marketType);
    }
}
