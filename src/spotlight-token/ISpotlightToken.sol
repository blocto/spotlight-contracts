// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

/**
 * @dev A contract implementing ISpotlightTokenCollection must also implement IERC20.
 */
interface ISpotlightToken {
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
     * @dev The number of tokens that can be bought from a given amount of USDC during bonding curve phase.
     * @notice The decimals of USDC is 6.
     */
    function getUSDCBuyQuote(uint256 usdcOrderSize) external view returns (uint256);

    /**
     * @dev The amount of USDC needed to buy a given number of tokens during bonding curve phase.
     * @notice The decimals of USDC is 6.
     */
    function getTokenBuyQuote(uint256 tokenOrderSize) external view returns (uint256);

    /**
     * @dev The amount of USDC that can be received for selling a given number of tokens during bonding curve phase.
     * @notice The decimals of USDC is 6.
     */
    function getTokenSellQuote(uint256 tokenOrderSize) external view returns (uint256);
}
