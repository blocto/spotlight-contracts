// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ISpotlightProtocolRewards} from "./ISpotlightProtocolRewards.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @dev Manager of deposits & withdrawals for protocol rewards
 */
contract SpotlightProtocolRewards is ISpotlightProtocolRewards, Ownable {
    constructor() payable Ownable(msg.sender) {}

    mapping(address => mapping(uint256 => uint256)) internal _rewards;
    bool internal _withdrawEnabled = false;

    error AddressZero();
    error RewardsZero();
    error AmountZero();
    error InvalidWithdraw();
    error TransferFailed();
    error TokenCallFailed();
    error InvalidReturnData();
    error WithdrawDisabled();
    error IpaIdsEmpty();

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
     * @param ipaId The IpaId to deposit rewards for
     */
    function deposit(address ipaId) external payable {
        if (ipaId == address(0)) revert AddressZero();
        uint256 amount = msg.value;
        if (amount == 0) revert AmountZero();

        (, address tokenContract, uint256 tokenId) = _getToken(ipaId);
        _rewards[tokenContract][tokenId] += amount;

        emit Deposit(tokenContract, tokenId, amount);
    }

    /*
     * @dev Withdraw protocol rewards
     * 
     * @param ipaId The IpaId to withdraw rewards from
     */
    function withdraw(address ipaId) external onlyWithdrawEnabled {
        if (ipaId == address(0)) revert AddressZero();

        (, address tokenContract, uint256 tokenId) = _getToken(ipaId);
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
     * @param ipaIds Array of IpaIds to withdraw rewards from
     */
    function withdrawAll(address[] calldata ipaIds) external onlyWithdrawEnabled {
        if (ipaIds.length == 0) revert IpaIdsEmpty();

        uint256 totalAmount;
        WithdrawInfo[] memory withdrawals = new WithdrawInfo[](ipaIds.length);

        for (uint256 i = 0; i < ipaIds.length; i++) {
            address ipaId = ipaIds[i];
            if (ipaId == address(0)) revert AddressZero();

            (, address tokenContract, uint256 tokenId) = _getToken(ipaId);
            if (!_checkIsOwner(tokenContract, tokenId)) revert InvalidWithdraw();

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
     * @dev Get the specific rewards for an IpaId
     *
     * @param ipaId The address to check the rewards for
     * 
     * @return uint256 The specific rewards for the IpaId
     */
    function rewardsOf(address ipaId) external view returns (uint256) {
        if (ipaId == address(0)) revert AddressZero();

        (, address tokenContract, uint256 tokenId) = _getToken(ipaId);
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
     * @param ipaId The address of the contract to call
     * 
     * @return chainId The EIP-155 ID of the chain the token exists on
     * @return tokenContract The contract address of the token
     * @return tokenId The ID of the token
     */
    function _getToken(address ipaId) internal view returns (uint256 chainId, address tokenContract, uint256 tokenId) {
        bytes memory callData = abi.encodeWithSignature("token()");
        (bool success, bytes memory returnData) = ipaId.staticcall(callData);
        if (!success) revert TokenCallFailed();
        if (returnData.length != 96) revert InvalidReturnData();

        (chainId, tokenContract, tokenId) = abi.decode(returnData, (uint256, address, uint256));

        if (tokenContract == address(0)) revert AddressZero();
    }

    function _checkIsOwner(address tokenContract, uint256 tokenId) internal view returns (bool) {
        address owner = msg.sender;
        IERC721 token = IERC721(tokenContract);
        return token.ownerOf(tokenId) == owner;
    }
}
