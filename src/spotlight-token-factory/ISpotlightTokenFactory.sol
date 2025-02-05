// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {StoryWorkflowStructs} from "./story-workflow-interfaces/StoryWorkflowStructs.sol";

interface ISpotlightTokenFactory {
    /*
     * @param tokenName_ The name of the token.
     * @param tokenSymbol_ The symbol of the token.
     * @param predeployedTokenAddress The address of the predeployed token. The transaction reverts if the actual token address differs.
     * @param tokenIpNFTId The tokenId of the NFT representing the IP associated with the token.
     */
    struct TokenCreationData {
        string tokenName;
        string tokenSymbol;
        address predeployedTokenAddress;
        uint256 tokenIpNFTId;
    }

    /*
     * @param initialBuyAmount The amount of tokens to be purchased initially.
     * @param initialBuyRecipient The recipient address for the initial token purchase.
     */
    struct IntialBuyData {
        uint256 initialBuyAmount;
        address initialBuyRecipient;
    }

    /**
     * @dev Emitted when a new Spotlight token is successfully created.
     *
     * @param createdTokenAddress The address of the newly created token.
     * @param ipId The ID of the Story Ip associated with the token.
     * @param tokenCreator The account that created the token.
     * @param tokenName The name of the created token.
     * @param tokenSymbol The symbol of the created token.
     * @param tokenIpNFTId The ID of the NFT representing the IP associated with the token.
     * @param initialBuyAmount The amount of tokens purchased initially.
     * @param initialBuyRecipient The address that received the initial purchased tokens.
     * @param fee The fee amount paid for the token creation.
     * @param factory The address of the factory contract used for token creation.
     * @param bondingCurve The address of the bonding curve contract used for token economics.
     */
    event SpotlightTokenCreated(
        address createdTokenAddress,
        address ipId,
        address tokenCreator,
        string tokenName,
        string tokenSymbol,
        uint256 tokenIpNFTId,
        uint256 initialBuyAmount,
        address initialBuyRecipient,
        uint256 fee,
        address factory,
        address bondingCurve
    );

    /**
     * @dev Returns if the token factory has been initialized.
     */
    function isInitialized() external view returns (bool);

    /**
     * @dev Initializes the token factory.
     *
     * @param owner_ The address of the token factory owner.
     * @param creationFee_ The fee to create a token.
     * @param tokenIpCollection_ The address of the token IP collection contract.
     * @param tokenImplementation_ The address of the token implementation contract.
     * @param bondingCurve_ The address of the bonding curve contract.
     * @param storyDerivativeWorkflows_ The address of the story derivative workflows contract.
     * @param piperXRouter_ The address of the PiperX router contract.
     * @param piperXFactory_ The address of the PiperX factory contract.
     * @param rewardsVault_ The address of the reward vault contract.
     */
    function initialize(
        address owner_,
        uint256 creationFee_,
        address tokenIpCollection_,
        address tokenImplementation_,
        address bondingCurve_,
        address storyDerivativeWorkflows_,
        address piperXRouter_,
        address piperXFactory_,
        address rewardsVault_
    ) external;

    /**
     * @dev Returns the fee amount required to create a token (in native token)
     */
    function createTokenFee() external view returns (uint256);

    /**
     * @dev Sets the fee amount required to create a token (in native token)
     */
    function setCreateTokenFee(uint256 newFee) external;

    /**
     * @dev Returns the address of the token IP collection contract
     * @notice The token IP collection contract must implement ISpotlightTokenIPCollection
     */
    function tokenIpCollection() external view returns (address);

    /**
     * @dev Returns the address of the token implementation contract
     */
    function tokenImplementation() external view returns (address);

    /**
     * @dev Sets the address of the token implementation contract
     */
    function setTokenImplementation(address newTokenImplementation) external;

    /**
     * @dev Returns the address of the bonding curve contract
     */
    function bondingCurve() external view returns (address);

    /**
     * @dev Sets the address of the bonding curve contract
     */
    function setBondingCurve(address newBondingCurve) external;

    /**
     * @dev Returns the address of the story derivative workflows contract
     */
    function storyDerivativeWorkflows() external view returns (address);

    /**
     * @dev Returns the address of the PiperX router contract
     */
    function piperXRouter() external view returns (address);

    /**
     * @dev Returns the address of the PiperX factory contract
     */
    function piperXFactory() external view returns (address);

    /**
     * @dev Returns the address of the rewards vault contract
     */
    function rewardsVault() external view returns (address);

    /**
     * @dev Computes the address of a token created by the specified token creator.
     * @param tokenCreator The address of the entity creating the token.
     * @return The calculated token address.
     */
    function calculateTokenAddress(address tokenCreator) external view returns (address);

    /**
     * @dev Creates a new token with the specified parameters and initializes it.
     * @notice Creation fee must be paid in native token.
     * @param tokenCreationData Details for creating the token.
     * @param initialBuyData Details for the initial purchase of the token.
     * @param derivData Details for creating a derivative token. See {IStoryDerivativeWorkflows-registerIpAndMakeDerivative}.
     * @param ipMetadata Metadata for the intellectual property. See {IStoryDerivativeWorkflows-registerIpAndMakeDerivative}.
     * @param sigMetadataAndRegister Signature data for token creation and IP registration. See {IStoryDerivativeWorkflows-registerIpAndMakeDerivative}.
     *
     * @return tokenAddress The address of the newly created token.
     * @return ipId The ID of the newly registered intellectual property.
     */
    function createToken(
        TokenCreationData memory tokenCreationData,
        IntialBuyData memory initialBuyData,
        StoryWorkflowStructs.MakeDerivative calldata derivData,
        StoryWorkflowStructs.IPMetadata calldata ipMetadata,
        StoryWorkflowStructs.SignatureData calldata sigMetadataAndRegister
    ) external payable returns (address tokenAddress, address ipId);

    /**
     * @dev Returns the number of tokens created by a token creator
     */
    function numberOfTokensCreated(address tokenCreator) external view returns (uint256);

    /**
     * @notice Allows the owner to claim the fee accumulated in the contract
     */
    function claimFee(address recipient) external;
}
