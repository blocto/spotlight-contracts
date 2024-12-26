// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {StoryWorkflowStructs} from "./story-workflow-interfaces/StoryWorkflowStructs.sol";

interface ISpotlightTokenFactory {
    /*
     * @param tokenName_ The name of the token.
     * @param tokenSymbol_ The symbol of the token.
     * @param predeployedTokenAddress The address of the predeployed token. The transaction reverts if the actual token address differs.
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
     * @param tokenBeacon_ The address of the token beacon contract.
     * @param bondingCurve_ The address of the bonding curve contract.
     * @param storyDerivativeWorkflows_ The address of the story derivative workflows contract.
     */
    function initialize(
        address owner_,
        uint256 creationFee_,
        address tokenIpCollection_,
        address tokenBeacon_,
        address bondingCurve_,
        address baseToken_,
        address storyDerivativeWorkflows_
    ) external;

    /**
     * @dev Returns the address of the token factory owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Returns the address of the token IP collection contract
     * @notice The token IP collection contract must implement ISpotlightTokenIPCollection
     */
    function tokenIpCollection() external view returns (address);

    /**
     * @dev Sets the address of the token IP collection contract
     * @notice The token IP collection contract must implement ISpotlightTokenIPCollection
     */
    function setTokenIpCollection(address newTokenIpCollection) external;

    /**
     * @dev Returns the address of the token beacon contract
     */
    function tokenBeacon() external view returns (address);

    /**
     * @dev Sets the address of the token beacon contract
     */
    function setTokenBeacon(address newTokenBeacon) external;

    /**
     * @dev Returns the fee amount required to create a token (in native token)
     */
    function createTokenFee() external view returns (uint256);

    /**
     * @dev Sets the fee amount required to create a token (in native token)
     */
    function setCreateTokenFee(uint256 newFee) external;

    /**
     * @dev Returns the address of the story derivative workflows contract
     */
    function storyDerivativeWorkflows() external view returns (address);

    /**
     * @dev Sets the address of the story derivative workflows contract
     */
    function setStoryDerivativeWorkflows(address newStoryDerivativeWorkflows) external;

    /**
     * @dev Returns the address of the base token
     */
    function baseToken() external view returns (address);

    /**
     * @dev Sets the address of the base token
     */
    function setBaseToken(address newBaseToken) external;

    /**
     * @dev Returns the address of the bonding curve contract
     */
    function bondingCurve() external view returns (address);

    /**
     * @dev Sets the address of the bonding curve contract
     */
    function setBindingCurve(address newBondingCurve) external;

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
     * @param sigMetadata Signature data for token creation. See {IStoryDerivativeWorkflows-registerIpAndMakeDerivative}.
     * @param sigRegister Signature data for IP registration. See {IStoryDerivativeWorkflows-registerIpAndMakeDerivative}.
     *
     * @return tokenAddress The address of the newly created token.
     * @return ipId The ID of the newly registered intellectual property.
     */
    function createToken(
        TokenCreationData memory tokenCreationData,
        IntialBuyData memory initialBuyData,
        StoryWorkflowStructs.MakeDerivative calldata derivData,
        StoryWorkflowStructs.IPMetadata calldata ipMetadata,
        StoryWorkflowStructs.SignatureData calldata sigMetadata,
        StoryWorkflowStructs.SignatureData calldata sigRegister
    ) external payable returns (address tokenAddress, address ipId);

    /**
     * @dev Returns the quote for initial buying tokens
     * @param tokensOut The number of tokens to be bought
     */
    function getInitialBuyTokenQuote(uint256 tokensOut) external view returns (uint256);

    /**
     * @dev Returns the number of tokens created by a token creator
     */
    function numberOfTokensCreated(address tokenCreator) external view returns (uint256);

    /**
     * @notice Allows the owner to claim the fee accumulated in the contract
     */
    function claimFee(address recipient) external;
}
