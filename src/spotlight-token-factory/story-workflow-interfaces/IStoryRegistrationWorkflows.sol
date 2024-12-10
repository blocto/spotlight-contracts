// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {StoryWorkflowStructs} from "./StoryWorkflowStructs.sol";

interface IStoryRegistrationWorkflows {
    /// @notice Registers an NFT as IP with metadata.
    /// @param nftContract The address of the NFT collection.
    /// @param tokenId The ID of the NFT.
    /// @param ipMetadata OPTIONAL. The desired metadata for the newly registered IP.
    /// @param sigMetadata OPTIONAL. Signature data for setAll (metadata) for the IP via the Core Metadata Module.
    /// @return ipId The ID of the newly registered IP.
    function registerIp(
        address nftContract,
        uint256 tokenId,
        StoryWorkflowStructs.IPMetadata calldata ipMetadata,
        StoryWorkflowStructs.SignatureData calldata sigMetadata
    ) external returns (address ipId);
}
