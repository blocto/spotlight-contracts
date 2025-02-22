// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IStoryDerivativeWorkflows} from
    "../../src/spotlight-token-factory/story-workflow-interfaces/IStoryDerivativeWorkflows.sol";
import {StoryWorkflowStructs} from
    "../../src/spotlight-token-factory/story-workflow-interfaces/StoryWorkflowStructs.sol";
import "../../lib/forge-std/src/Test.sol";

contract MockStoryDerivativeWorkflows is IStoryDerivativeWorkflows, Test {
    address public mockReturnAddress;
    uint256 public callCount;
    address public mockParentIPAccount;

    StoryWorkflowStructs.MakeDerivative public mockMakeDerivative;
    StoryWorkflowStructs.IPMetadata public mockIpMetadata;
    StoryWorkflowStructs.SignatureData public mockSigMetadataAndRegister;

    event RegisterCalled(
        address collection,
        uint256 tokenId,
        StoryWorkflowStructs.MakeDerivative derivData,
        StoryWorkflowStructs.IPMetadata ipMetadata,
        StoryWorkflowStructs.SignatureData sigMetadataAndRegister
    );

    constructor() {
        mockParentIPAccount = address(0x9ea65c24f87F6F196B435F65103204A463bcFF17);
        address[] memory parentIPAccounts = new address[](1);
        parentIPAccounts[0] = mockParentIPAccount;

        mockMakeDerivative = StoryWorkflowStructs.MakeDerivative({
            parentIpIds: parentIPAccounts,
            licenseTemplate: address(0),
            licenseTermsIds: new uint256[](0),
            royaltyContext: "",
            maxMintingFee: 0,
            maxRts: 0,
            maxRevenueShare: 0
        });

        mockIpMetadata = StoryWorkflowStructs.IPMetadata({
            ipMetadataURI: "",
            ipMetadataHash: bytes32(uint256(1)),
            nftMetadataURI: "",
            nftMetadataHash: bytes32(uint256(2))
        });

        mockSigMetadataAndRegister =
            StoryWorkflowStructs.SignatureData({signer: address(0), deadline: block.timestamp + 1 days, signature: ""});
    }

    function getMockStructs()
        external
        view
        returns (
            StoryWorkflowStructs.MakeDerivative memory,
            StoryWorkflowStructs.IPMetadata memory,
            StoryWorkflowStructs.SignatureData memory
        )
    {
        return (mockMakeDerivative, mockIpMetadata, mockSigMetadataAndRegister);
    }

    function setMockReturnAddress(address _mockAddress) external {
        mockReturnAddress = _mockAddress;
    }

    function registerIpAndMakeDerivative(
        address collection,
        uint256 tokenId,
        StoryWorkflowStructs.MakeDerivative calldata derivData,
        StoryWorkflowStructs.IPMetadata calldata ipMetadata,
        StoryWorkflowStructs.SignatureData calldata sigMetadataAndRegister
    ) external returns (address) {
        callCount++;
        emit RegisterCalled(collection, tokenId, derivData, ipMetadata, sigMetadataAndRegister);
        return mockReturnAddress;
    }
}
