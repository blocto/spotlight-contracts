// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ISpotlightProtocolRewards {
    /**
     * @dev Struct to hold withdrawal information
     */
    struct WithdrawInfo {
        address nftContract;
        uint256 tokenId;
        uint256 amount;
    }

    /**
     * @dev Emitted when rewards are deposited for an IPA.
     *
     * @param nftContract The NFT contract address.
     * @param tokenId The NFT token ID.
     * @param amount The amount of rewards deposited.
     */
    event Deposit(address nftContract, uint256 tokenId, uint256 amount);

    /**
     * @dev Emitted when rewards are withdrawn for a specific IPA.
     *
     * @param withdrawal The withdrawal information (nftContract, tokenId, amount).
     */
    event Withdraw(WithdrawInfo withdrawal);

    /**
     * @dev Emitted when rewards are withdrawn in batch.
     * Each tuple contains (nftContract, tokenId, amount) for a withdrawal.
     *
     * @param withdrawals Array of withdrawal tuples.
     */
    event WithdrawAll(WithdrawInfo[] withdrawals);

    /**
     * @dev Deposits rewards for an IPA.
     * - The caller provides ETH value to deposit as rewards.
     * - Emits a Deposit event.
     *
     * @param ipaId The IPA identifier address to deposit rewards for.
     */
    function deposit(address ipaId) external payable;

    /**
     * @dev Withdraws rewards for a specific IPA.
     * - Only the IPA owner can withdraw.
     * - Requires withdraw functionality to be enabled.
     * - Emits a Withdraw event.
     *
     * @param ipaId The IPA identifier address to withdraw rewards from.
     */
    function withdraw(address ipaId) external;

    /**
     * @dev Withdraws rewards for multiple IPAs at once.
     * - Only IPA owners can withdraw their respective rewards.
     * - Requires withdraw functionality to be enabled.
     * - Emits a Withdraw event with total amount.
     *
     * @param ipaIds Array of IPA identifier addresses to withdraw rewards from.
     */
    function withdrawAll(address[] calldata ipaIds) external;

    /**
     * @dev Returns the pending rewards for an IPA.
     *
     * @param ipaId The IPA identifier address to check rewards for.
     * @return The amount of pending rewards.
     */
    function rewardsOf(address ipaId) external view returns (uint256);

    /**
     * @dev Returns the total rewards held in the contract.
     *
     * @return The total amount of rewards.
     */
    function totalRewards() external view returns (uint256);

    /**
     * @dev Returns whether the withdraw functionality is currently enabled.
     *
     * @return True if withdraw is enabled, false otherwise.
     */
    function isWithdrawEnabled() external view returns (bool);
}
