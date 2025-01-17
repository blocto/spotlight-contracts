// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

enum MarketType {
    BONDING_CURVE,
    PIPERX_POOL
}

struct MarketState {
    MarketType marketType;
    address marketAddress;
}

/**
 * @dev A contract implementing ISpotlightTokenCollection must also implement IERC20.
 */
interface ISpotlightToken {
    /**
     * @dev Emitted when tokens are bought.
     *
     * @param buyer The address of the buyer.
     * @param recipient The address that received the tokens.
     * @param totalIPIn The total amount of IP spent.
     * @param tradingFee The trading fee paid.
     * @param ipUsedToBuy The amount of IP used to buy the tokens.
     * @param tokensBought The amount of tokens bought.
     * @param totalSupply The total supply of tokens after the transaction.
     */
    event SpotlightTokenBought(
        address buyer,
        address recipient,
        uint256 totalIPIn,
        uint256 tradingFee,
        uint256 ipUsedToBuy,
        uint256 tokensBought,
        uint256 totalSupply
    );

    /**
     * @dev Emitted when tokens are sold.
     *
     * @param seller The address of the seller.
     * @param recipient The address that received the IP proceeds.
     * @param finalIPOut The total amount of IP user received.
     * @param tradingFee The trading fee paid.
     * @param ipReceivedFromSelling The amount of IP received from selling the tokens.
     * @param tokensSold The amount of tokens sold.
     * @param totalSupply The total supply of tokens after the transaction.
     */
    event SpotlightTokenSold(
        address seller,
        address recipient,
        uint256 finalIPOut,
        uint256 tradingFee,
        uint256 ipReceivedFromSelling,
        uint256 tokensSold,
        uint256 totalSupply
    );

    /**
     * @dev Emitted when a market graduates
     *
     * @param tokenAddress The address of the token
     * @param poolAddress The address of the pool
     * @param totalEthLiquidity The total ETH liquidity in the pool
     * @param totalTokenLiquidity The total token liquidity in the pool
     * @param liquidity The liquidity of the pool
     * @param marketType The type of market
     */
    event SpotlightTokenGraduated(
        address indexed tokenAddress,
        address indexed poolAddress,
        uint256 totalEthLiquidity,
        uint256 totalTokenLiquidity,
        uint256 liquidity,
        MarketType marketType
    );

    /**
     * @dev Initializes the token.
     *
     * @param owner_ The address of the token owner.
     * @param tokenCreator_ The address of the token creator.
     * @param bondingCurve_ The address of the bonding curve.
     * @param baseToken_ The address of the base token.
     * @param protocolFeeRecipient_ The address of the protocol fee recipient.
     * @param tokenName_ The name of the token.
     * @param tokenSymbol_ The symbol of the token.
     * @param piperXRouter_ The address of the piperX router.
     * @param piperXFactory_ The address of the piperX factory.
     * @param specificAddress_ The address of the specific address.
     * @param protocolRewards_ The address of the protocol rewards.
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
        address piperXFactory_,
        address specificAddress_,
        address protocolRewards_
    ) external;

    /**
     * @dev Returns if the token has been initialized.
     */
    function isInitialized() external view returns (bool);

    /**
     * @dev Returns the address of the token owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Returns the address of the token creator.
     */
    function tokenCreator() external view returns (address);

    /**
     * @dev Returns the address of the protocol fee recipient.
     */
    function protocolFeeRecipient() external view returns (address);

    /**
     * @dev Sets the address of the protocol fee recipient.
     */
    function setProtocolFeeRecipient(address newRecipient) external;

    /**
     * @dev Returns the address of the bonding curve.
     */
    function bondingCurve() external view returns (address);

    /**
     * @dev Returns the current market state.
     */
    function state() external view returns (MarketState memory);

    /**
     * @dev Purchases tokens by specifying the amount of IP to spend.
     * - The caller provides the amount of IP they want to spend.
     * - Ensures at least `minTokenOut` tokens are received, reverting otherwise.
     *
     * @param recipient The address that will receive the purchased tokens.
     * @param minTokenOut The minimum amount of tokens to receive for the transaction to succeed.
     * @param expectedMarketType The expected market type.
     */
    function buyWithIP(address recipient, uint256 minTokenOut, MarketType expectedMarketType) external payable;

    /**
     * @dev Purchases tokens by specifying the desired token amount to buy.
     * - The caller specifies the number of tokens they wish to purchase.
     * - Ensures the IP spent does not exceed `maxIPIn`, reverting otherwise.
     *
     * @param tokenAmount The amount of tokens to purchase.
     * @param recipient The address that will receive the purchased tokens.
     */
    function buyToken(uint256 tokenAmount, address recipient, MarketType expectedMarketType) external payable;

    /**
     * @dev Sells tokens for IP.
     * - The caller specifies the amount of tokens they want to sell.
     * - Ensures at least `minIPOut` is received, reverting the transaction otherwise.
     *
     * @param tokenAmount The amount of tokens to sell.
     * @param recipient The address that will receive the IP proceeds.
     * @param minIPOut The minimum amount of IP to receive for the transaction to succeed. Please note that the trading fee is included in this amount.
     */
    function sellToken(uint256 tokenAmount, address recipient, uint256 minIPOut, MarketType expectedMarketType)
        external;

    /**
     * @dev The number of tokens that can be bought from a given amount of IP during bonding curve phase.
     */
    function getIPBuyQuote(uint256 ipOrderSize) external view returns (uint256 tokensOut);

    /**
     * @dev The amount of IP needed to buy a given number of tokens during bonding curve phase.
     */
    function getTokenBuyQuote(uint256 tokenOrderSize) external view returns (uint256 ipIn);

    /**
     * @dev The amount of IP that can be received for selling a given number of tokens during bonding curve phase.
     */
    function getTokenSellQuote(uint256 tokenOrderSize) external view returns (uint256 ipOut);

    /**
     * @dev The number of tokens that can be bought from a given amount of IP during bonding curve phase.
     * @notice The quote is considered with the protocol trading fee.
     */
    function getIPBuyQuoteWithFee(uint256 ipOrderSize) external view returns (uint256 tokensOut);

    /**
     * @dev The amount of IP needed to buy a given number of tokens during bonding curve phase.
     * @notice The quote is considered with the protocol trading fee.
     */
    function getTokenBuyQuoteWithFee(uint256 tokenOrderSize) external view returns (uint256 ipIn);

    /**
     * @dev The amount of IP that can be received for selling a given number of tokens during bonding curve phase.
     * @notice The quote is considered with the protocol trading fee.
     */
    function getTokenSellQuoteWithFee(uint256 tokenOrderSize) external view returns (uint256 ipOut);
}
