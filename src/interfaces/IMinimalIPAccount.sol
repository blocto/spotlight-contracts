// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

// ref: https://github.com/storyprotocol/protocol-core-v1/blob/main/contracts/interfaces/IIPAccount.sol
interface IMinimalIPAccount {
    /// @notice Returns the identifier of the non-fungible token which owns the account
    /// @return chainId The EIP-155 ID of the chain the token exists on
    /// @return tokenContract The contract address of the token
    /// @return tokenId The ID of the token
    function token() external view returns (uint256, address, uint256);
}
