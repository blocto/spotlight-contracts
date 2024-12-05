// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface ISpotlightFaucet {
    /**
     * @dev Returns the amount of tokens that can be claimed from the faucet at once.
     */
    function faucetClaimAmount() external view returns (uint256);

    /**
     * @dev Returns whether the faucet is active.
     */
    function isFaucetActive() external view returns (bool);

    /**
     * @dev Sets whether the faucet is active.
     */
    function setFaucetActive(bool active) external;

    /**
     * @dev Returns whether the wait time is active.
     */
    function isWaitTimeActive() external view returns (bool);

    /**
     * @dev Sets whether the wait time is active.
     */
    function setWaitTimeActive(bool active) external;

    /**
     * @dev Returns the wait time in seconds.
     */
    function waitTime() external view returns (uint256);

    /**
     * @dev Sets the wait time in seconds.
     */
    function setWaitTime(uint256 newWaitTime) external;

    /**
     * @dev Returns the timestamp of the last claim for an account.
     */
    function lastClaimTimestamp(address account) external view returns (uint256);

    /**
     * @dev Returns the number of seconds until the next claim for an account.
     */
    function secondsUntilNextClaim(address account) external view returns (uint256);

    /**
     * @dev Claims tokens from the faucet.
     */
    function claimToken() external;

    /**
     * @dev Distributes tokens to an account.
     */
    function distributeToken(address account, uint256 value) external;
}
