// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

/**
 * @dev A contract implementing ISpotlightTokenCollection must also implement IERC20.
 */
interface ISpotlightToken {
    /**
     * @dev Emitted when tokens are bought.
     *
     * @param buyer The address of the buyer.
     * @param recipient The address that received the tokens.
     * @param totalUSDCIn The total amount of USDC spent.
     * @param tradingFee The trading fee paid.
     * @param usdcUsedToBuy The amount of USDC used to buy the tokens.
     * @param tokensBought The amount of tokens bought.
     * @param totalSupply The total supply of tokens after the transaction.
     */
    event SpotlightTokenBought(
        address buyer,
        address recipient,
        uint256 totalUSDCIn,
        uint256 tradingFee,
        uint256 usdcUsedToBuy,
        uint256 tokensBought,
        uint256 totalSupply
    );

    /**
     * @dev Emitted when tokens are sold.
     *
     * @param seller The address of the seller.
     * @param recipient The address that received the USDC proceeds.
     * @param finalUSDCOut The total amount of USDC user received.
     * @param tradingFee The trading fee paid.
     * @param usdcReceivedFromSelling The amount of USDC received from selling the tokens.
     * @param tokensSold The amount of tokens sold.
     * @param totalSupply The total supply of tokens after the transaction.
     */
    event SpotlightTokenSold(
        address seller,
        address recipient,
        uint256 finalUSDCOut,
        uint256 tradingFee,
        uint256 usdcReceivedFromSelling,
        uint256 tokensSold,
        uint256 totalSupply
    );

    /**
     * @dev Returns if the token has been initialized.
     */
    function isInitialized() external view returns (bool);

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
     * @dev Purchases tokens by specifying the amount of USDC to spend.
     * - The caller provides the amount of USDC they want to spend.
     * - Ensures at least `minTokenOut` tokens are received, reverting otherwise.
     *
     * @param usdcAmount The amount of USDC to spend. Please note that the trading fee is included in this amount.
     * @param recipient The address that will receive the purchased tokens.
     * @param minTokenOut The minimum amount of tokens to receive for the transaction to succeed.
     */
    function buyWithUSDC(uint256 usdcAmount, address recipient, uint256 minTokenOut) external;

    /**
     * @dev Purchases tokens by specifying the desired token amount to buy.
     * - The caller specifies the number of tokens they wish to purchase.
     * - Ensures the USDC spent does not exceed `maxUSDCIn`, reverting otherwise.
     *
     * @param tokenAmount The amount of tokens to purchase.
     * @param recipient The address that will receive the purchased tokens.
     * @param maxUSDCIn The maximum amount of USDC the caller is willing to spend. Please note that the trading fee is included in this amount.
     */
    function buyToken(uint256 tokenAmount, address recipient, uint256 maxUSDCIn) external;

    /**
     * @dev Sells tokens for USDC.
     * - The caller specifies the amount of tokens they want to sell.
     * - Ensures at least `minUSDCOut` is received, reverting the transaction otherwise.
     *
     * @param tokenAmount The amount of tokens to sell.
     * @param recipient The address that will receive the USDC proceeds.
     * @param minUSDCOut The minimum amount of USDC to receive for the transaction to succeed. Please note that the trading fee is included in this amount.
     */
    function sellToken(uint256 tokenAmount, address recipient, uint256 minUSDCOut) external;

    /**
     * @dev The number of tokens that can be bought from a given amount of USDC during bonding curve phase.
     * @notice The decimals of USDC is 6.
     */
    function getUSDCBuyQuote(uint256 usdcOrderSize) external view returns (uint256 tokensOut);

    /**
     * @dev The amount of USDC needed to buy a given number of tokens during bonding curve phase.
     * @notice The decimals of USDC is 6.
     */
    function getTokenBuyQuote(uint256 tokenOrderSize) external view returns (uint256 usdcIn);

    /**
     * @dev The amount of USDC that can be received for selling a given number of tokens during bonding curve phase.
     * @notice The decimals of USDC is 6.
     */
    function getTokenSellQuote(uint256 tokenOrderSize) external view returns (uint256 usdcOut);

    /**
     * @dev The number of tokens that can be bought from a given amount of USDC during bonding curve phase.
     * @notice The decimals of USDC is 6.
     * @notice The quote is considered with the protocol trading fee.
     */
    function getUSDCBuyQuoteWithFee(uint256 usdcOrderSize) external view returns (uint256 tokensOut);

    /**
     * @dev The amount of USDC needed to buy a given number of tokens during bonding curve phase.
     * @notice The decimals of USDC is 6.
     * @notice The quote is considered with the protocol trading fee.
     */
    function getTokenBuyQuoteWithFee(uint256 tokenOrderSize) external view returns (uint256 usdcIn);

    /**
     * @dev The amount of USDC that can be received for selling a given number of tokens during bonding curve phase.
     * @notice The decimals of USDC is 6.
     * @notice The quote is considered with the protocol trading fee.
     */
    function getTokenSellQuoteWithFee(uint256 tokenOrderSize) external view returns (uint256 usdcOut);
}
