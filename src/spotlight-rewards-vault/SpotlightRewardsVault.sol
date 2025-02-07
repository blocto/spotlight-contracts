// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ISpotlightRewardsVault} from "./ISpotlightRewardsVault.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {IMinimalIPAccount} from "../interfaces/IMinimalIPAccount.sol";
/*
 * @dev Manager of deposits & withdrawals for protocol rewards
 */

contract SpotlightRewardsVault is ISpotlightRewardsVault, Ownable, ReentrancyGuardTransient {
    constructor() payable Ownable(msg.sender) {}

    mapping(address => mapping(uint256 => uint256)) internal _rewards;
    bool internal _withdrawEnabled = false;

    error AddressZero();
    error RewardsZero();
    error AmountZero();
    error InvalidWithdraw();
    error TransferFailed();
    error TokenCallFailed();
    error WithdrawDisabled();
    error IPAccountsEmpty();

    modifier onlyWithdrawEnabled() {
        if (!_withdrawEnabled) revert WithdrawDisabled();
        _;
    }

    /*
     * @dev The total amount of IP held in the contract
     *
     * @return uint256 Total IP balance
     */
    function totalRewards() external view returns (uint256) {
        return address(this).balance;
    }

    /*
     * @dev Deposit protocol rewards
     *
     * @param ipAccount The IPAccount to deposit rewards for
     */
    function deposit(address ipAccount) external payable {
        if (ipAccount == address(0)) revert AddressZero();
        uint256 amount = msg.value;
        if (amount == 0) revert AmountZero();

        (, address tokenContract, uint256 tokenId) = _getToken(ipAccount);
        _rewards[tokenContract][tokenId] += amount;

        emit Deposit(tokenContract, tokenId, amount);
    }

    /*
     * @dev Withdraw protocol rewards
     *
     * @param ipAccount The IPAccount to withdraw rewards from
     */
    function withdraw(address ipAccount) external onlyWithdrawEnabled nonReentrant {
        if (ipAccount == address(0)) revert AddressZero();

        (, address tokenContract, uint256 tokenId) = _getToken(ipAccount);
        if (!_checkIsOwner(tokenContract, tokenId)) revert InvalidWithdraw();

        uint256 ownerRewards = this.rewardsOf(tokenContract, tokenId);
        if (ownerRewards == 0) revert RewardsZero();

        _rewards[tokenContract][tokenId] -= ownerRewards;

        emit Withdraw(WithdrawInfo({nftContract: tokenContract, tokenId: tokenId, amount: ownerRewards}));

        (bool success,) = msg.sender.call{value: ownerRewards}("");
        if (!success) revert TransferFailed();
    }

    /*
     * @dev Withdraw protocol rewards
     *
     * @param ipAccounts Array of IPAccounts to withdraw rewards from
     */
    function withdrawAll(address[] calldata ipAccounts) external onlyWithdrawEnabled nonReentrant {
        if (ipAccounts.length == 0) revert IPAccountsEmpty();

        uint256 totalAmount;
        WithdrawInfo[] memory withdrawals = new WithdrawInfo[](ipAccounts.length);

        for (uint256 i = 0; i < ipAccounts.length; i++) {
            address ipAccount = ipAccounts[i];
            if (ipAccount == address(0)) revert AddressZero();

            (, address tokenContract, uint256 tokenId) = _getToken(ipAccount);
            if (!_checkIsOwner(tokenContract, tokenId)) {
                revert InvalidWithdraw();
            }

            uint256 ownerRewards = this.rewardsOf(tokenContract, tokenId);
            if (ownerRewards == 0) continue;

            _rewards[tokenContract][tokenId] -= ownerRewards;
            totalAmount += ownerRewards;

            withdrawals[i] = WithdrawInfo({nftContract: tokenContract, tokenId: tokenId, amount: ownerRewards});
        }

        if (totalAmount == 0) revert RewardsZero();

        emit WithdrawAll(withdrawals);

        (bool success,) = msg.sender.call{value: totalAmount}("");
        if (!success) revert TransferFailed();
    }

    /*
     * @dev Is withdraw and withdrawAll functionality are enabled
     *
     * @return bool Is withdraw and withdrawAll functionality are enabled
     */
    function isWithdrawEnabled() external view returns (bool) {
        return _withdrawEnabled;
    }

    /*
     * @dev Enable withdraw and withdrawAll functionality
     */
    function setWithdrawEnabled(bool enabled) external onlyOwner {
        _withdrawEnabled = enabled;
    }

    /*
     * @dev Get the specific rewards for an IPAccount
     *
     * @param ipAccount The address to check the rewards for
     *
     * @return uint256 The specific rewards for the IPAccount
     */
    function rewardsOf(address ipAccount) external view returns (uint256) {
        if (ipAccount == address(0)) revert AddressZero();

        (, address tokenContract, uint256 tokenId) = _getToken(ipAccount);
        return this.rewardsOf(tokenContract, tokenId);
    }

    /*
     * @dev Get the specific rewards for a token
     *
     * @param tokenContract The contract address of the token
     * @param tokenId The ID of the token
     *
     * @return uint256 The specific rewards for the token
     */
    function rewardsOf(address tokenContract, uint256 tokenId) external view returns (uint256) {
        if (tokenContract == address(0)) revert AddressZero();

        return _rewards[tokenContract][tokenId];
    }

    /*
     * @dev Internal function to get token info using low level call
     * @param ipAccount The address of the contract to call
     *
     * @return chainId The EIP-155 ID of the chain the token exists on
     * @return tokenContract The contract address of the token
     * @return tokenId The ID of the token
     */
    function _getToken(address ipAccount)
        internal
        view
        returns (uint256 chainId, address tokenContract, uint256 tokenId)
    {
        (chainId, tokenContract, tokenId) = IMinimalIPAccount(ipAccount).token();
        if (tokenContract == address(0)) revert AddressZero();
    }

    function _checkIsOwner(address tokenContract, uint256 tokenId) internal view returns (bool) {
        address owner = msg.sender;
        IERC721 token = IERC721(tokenContract);
        return token.ownerOf(tokenId) == owner;
    }
}
