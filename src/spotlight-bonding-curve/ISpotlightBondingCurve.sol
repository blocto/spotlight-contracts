// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface ISpotlightBondingCurve {
    /**
     * @notice Target Token: The token being traded on the bonding curve in the primary market.
     * @notice Base Token: The token used as payment to purchase the target token.
     */

    /**
     * @dev Calculates the amount of base tokens that can be received by selling a specific amount of target tokens.
     * @param currentSupply The current supply of target tokens in the system.
     * @param targetTokensIn The amount of target tokens to sell.
     * @return baseTokensOut The equivalent amount of base tokens to be received.
     */
    function getTargetTokenSellQuote(uint256 currentSupply, uint256 targetTokensIn)
        external
        view
        returns (uint256 baseTokensOut);

    /**
     * @dev Calculates the amount of target tokens that can be purchased with a specific amount of base tokens.
     * @param currentSupply The current supply of target tokens in the system.
     * @param baseTokensIn The amount of base tokens used for the purchase.
     * @return targetTokensOut The equivalent amount of target tokens to be received.
     */
    function getBaseTokenBuyQuote(uint256 currentSupply, uint256 baseTokensIn)
        external
        view
        returns (uint256 targetTokensOut);

    /**
     * @dev Calculates the amount of base tokens required to purchase a specific amount of target tokens.
     * @param currentSupply The current supply of target tokens in the system.
     * @param targetTokensOut The amount of target tokens to purchase.
     * @return baseTokensIn The equivalent amount of base tokens required for the purchase.
     */
    function getTargetTokenBuyQuote(uint256 currentSupply, uint256 targetTokensOut)
        external
        view
        returns (uint256 baseTokensIn);
}
