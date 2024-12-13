// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

/**
 * @dev A contract implementing ISpotlightTokenCollection must also implement IERC721.
 */
interface ISpotlightTokenIPCollection {
    /**
     * @dev Returns the total number of tokens minted.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Sets the token URI for the collection.
     */
    function setTokenURI(string memory tokenURI_) external;

    /**
     * @dev Returns wether minting is enabled.
     */
    function isMintEnabled() external view returns (bool);

    /**
     * @dev Sets whether minting is enabled.
     */
    function setMintEnabled(bool enabled) external;

    /**
     * @dev Returns the address of the token factory.
     */
    function tokenFactory() external view returns (address);

    /**
     * @dev Sets the address of the token factory.
     */
    function setTokenFactory(address newTokenFactory) external;

    /**
     * @dev Returns the total number of tokens minted.
     */
    function isTransferEnabled() external view returns (bool);

    /**
     * @dev Sets whether transfers are enabled.
     */
    function setTransferEnabled(bool enabled) external;

    /**
     * @dev Mints a new token and assigns it to the specified address.
     * @return The token ID of the newly minted token.
     */
    function mint(address to) external returns (uint256);
}
