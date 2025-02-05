// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {StoryWorkflowStructs} from "./StoryWorkflowStructs.sol";
// refer: https://github.com/storyprotocol/protocol-periphery-v1/blob/426f2b70c209d9f40ec0eafcc016a902d629abdf/contracts/interfaces/workflows/IDerivativeWorkflows.sol#L34
interface IStoryDerivativeWorkflows {
    /// @notice Register the given NFT as a derivative IP with metadata without license tokens.
    /// @param nftContract The address of the NFT collection.
    /// @param tokenId The ID of the NFT.
    /// @param derivData The derivative data to be used for registerDerivative.
    /// @param ipMetadata OPTIONAL. The desired metadata for the newly registered IP.
    /// @param sigMetadataAndRegister Signature data for setAll (metadata) for the IP via the Core Metadata Module
    /// and registerDerivative for the IP via the Licensing Module.
    /// @return ipId The ID of the newly registered IP.
    function registerIpAndMakeDerivative(
        address nftContract,
        uint256 tokenId,
        StoryWorkflowStructs.MakeDerivative calldata derivData,
        StoryWorkflowStructs.IPMetadata calldata ipMetadata,
        StoryWorkflowStructs.SignatureData calldata sigMetadataAndRegister
    ) external returns (address ipId);
}
