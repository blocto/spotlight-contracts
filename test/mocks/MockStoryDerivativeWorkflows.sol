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
    StoryWorkflowStructs.SignatureData public mockSigMetadata;
    StoryWorkflowStructs.SignatureData public mockSigRegister;

    event RegisterCalled(
        address collection,
        uint256 tokenId,
        StoryWorkflowStructs.MakeDerivative derivData,
        StoryWorkflowStructs.IPMetadata ipMetadata,
        StoryWorkflowStructs.SignatureData sigMetadata,
        StoryWorkflowStructs.SignatureData sigRegister
    );

    constructor() {
        mockParentIPAccount = address(0x359EcA9F3C4cCdB7C10Dd4D9410EaD52Ef9B430A);
        address[] memory parentIPAccounts = new address[](1);
        parentIPAccounts[0] = mockParentIPAccount;

        mockMakeDerivative = StoryWorkflowStructs.MakeDerivative({
            parentIpIds: parentIPAccounts,
            licenseTemplate: address(0),
            licenseTermsIds: new uint256[](0),
            royaltyContext: ""
        });

        mockIpMetadata = StoryWorkflowStructs.IPMetadata({
            ipMetadataURI: "",
            ipMetadataHash: bytes32(uint256(1)),
            nftMetadataURI: "",
            nftMetadataHash: bytes32(uint256(2))
        });

        mockSigMetadata =
            StoryWorkflowStructs.SignatureData({signer: address(0), deadline: block.timestamp + 1 days, signature: ""});

        mockSigRegister =
            StoryWorkflowStructs.SignatureData({signer: address(0), deadline: block.timestamp + 1 days, signature: ""});
    }

    function getMockStructs()
        external
        view
        returns (
            StoryWorkflowStructs.MakeDerivative memory,
            StoryWorkflowStructs.IPMetadata memory,
            StoryWorkflowStructs.SignatureData memory,
            StoryWorkflowStructs.SignatureData memory
        )
    {
        return (mockMakeDerivative, mockIpMetadata, mockSigMetadata, mockSigRegister);
    }

    function setMockReturnAddress(address _mockAddress) external {
        mockReturnAddress = _mockAddress;
    }

    function registerIpAndMakeDerivative(
        address collection,
        uint256 tokenId,
        StoryWorkflowStructs.MakeDerivative calldata derivData,
        StoryWorkflowStructs.IPMetadata calldata ipMetadata,
        StoryWorkflowStructs.SignatureData calldata sigMetadata,
        StoryWorkflowStructs.SignatureData calldata sigRegister
    ) external returns (address) {
        callCount++;
        emit RegisterCalled(collection, tokenId, derivData, ipMetadata, sigMetadata, sigRegister);
        return mockReturnAddress;
    }
}
