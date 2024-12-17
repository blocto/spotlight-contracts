// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ISpotlightFaucet} from "./ISpotlightFaucet.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SpotlightTokenFaucet is Ownable, ISpotlightFaucet {
    address private immutable _tokenAddress;
    ERC20 private _token;

    bool private _isFaucetActive = true;
    bool private _isWaitTimeActive = true;
    uint256 private _waitTime = 1 days;
    uint256 private _faucetClaimAmount;
    mapping(address => uint256) private _lastClaimTime;

    constructor(address tokenAddress_) Ownable(msg.sender) {
        _tokenAddress = tokenAddress_;
        _token = ERC20(tokenAddress_);
        _faucetClaimAmount = 1000 * 10 ** _token.decimals();
    }

    modifier onlyFaucetActive() {
        _checkIsFaucetActive();
        _;
    }

    /**
     * @dev See {ISpotlightFaucet-tokenAddress}.
     */
    function tokenAddress() public view returns (address) {
        return _tokenAddress;
    }

    /**
     * @dev See {ISpotlightFaucet-faucetClaimAmount}.
     */
    function faucetClaimAmount() public view returns (uint256) {
        return _faucetClaimAmount;
    }

    function setFaucetClaimAmount(uint256 newClaimAmount) public onlyOwner {
        _faucetClaimAmount = newClaimAmount;
    }

    /**
     * @dev See {ISpotlightFaucet-isFaucetActive}.
     */
    function isFaucetActive() public view returns (bool) {
        return _isFaucetActive;
    }

    /**
     * @dev See {ISpotlightFaucet-isFaucetActive}.
     * @notice onlyOwner
     */
    function setFaucetActive(bool active) external onlyOwner {
        _isFaucetActive = active;
    }

    /**
     * @dev See {ISpotlightFaucet-isWaitTimeActive}.
     */
    function isWaitTimeActive() public view returns (bool) {
        return _isWaitTimeActive;
    }

    /**
     * @dev See {ISpotlightFaucet-waitTime}.
     */
    function waitTime() external view returns (uint256) {
        if (!isWaitTimeActive()) {
            return 0;
        }
        return _waitTime;
    }

    /**
     * @dev See {ISpotlightFaucet-setWaitTime}.
     * @notice onlyOwner
     */
    function setWaitTime(uint256 newWaitTime) external onlyOwner {
        _waitTime = newWaitTime;
    }

    /**
     * @dev See {ISpotlightFaucet-setIsWaitTimeActive}.
     * @notice onlyOwner
     */
    function setWaitTimeActive(bool active) external onlyOwner {
        _isWaitTimeActive = active;
    }

    /**
     * @dev See {ISpotlightFaucet-lastClaimTimestamp}.
     */
    function lastClaimTimestamp(address account) public view returns (uint256) {
        return _lastClaimTime[account];
    }

    /**
     * @dev See {ISpotlightFaucet-secondsUntilNextClaim}.
     * @notice return 0 if the wait time is not active
     * @notice owner don't have to wait
     */
    function secondsUntilNextClaim(address account) public view returns (uint256) {
        if (!isWaitTimeActive()) {
            return 0;
        }

        if (account == owner()) {
            return 0;
        }

        if (lastClaimTimestamp(account) == 0) {
            return 0;
        }

        int256 remainingTime = int256(lastClaimTimestamp(account) + _waitTime - block.timestamp);
        if (remainingTime < 0) {
            return 0;
        } else {
            return uint256(remainingTime);
        }
    }

    /**
     * @dev See {ISpotlightFaucet-claimToken}.
     * @dev Emits a {Transfer} event with `from` set to the zero address.
     */
    function claimToken() external onlyFaucetActive {
        if (secondsUntilNextClaim(msg.sender) > 0) {
            revert("SpotlightTokenFaucet: wait time has not passed");
        }

        _lastClaimTime[msg.sender] = block.timestamp;
        _token.transfer(msg.sender, _faucetClaimAmount);
    }

    /**
     * @dev See {ISpotlightFaucet-distributeToken}.
     * @dev Emits a {Transfer} event with `from` set to the zero address.
     * @notice onlyOwner
     */
    function distributeToken(address account, uint256 value) external override onlyOwner {
        _token.transfer(account, value);
    }

    /**
     * @dev Reverts if the faucet is not active.
     */
    function _checkIsFaucetActive() internal view {
        if (!isFaucetActive()) {
            revert("SpotlightTokenFaucet: faucet is not active");
        }
    }
}
