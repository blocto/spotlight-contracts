// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISpotlightTokenFactory} from "./ISpotlightTokenFactory.sol";
import {SpotlightToken} from "../spotlight-token/SpotlightToken.sol";
import {SpotlightTokenIPCollection} from "../spotlight-token-collection/SpotlightTokenIPCollection.sol";
import {StoryWorkflowStructs} from "./story-workflow-interfaces/StoryWorkflowStructs.sol";
import {IStoryDerivativeWorkflows} from "./story-workflow-interfaces/IStoryDerivativeWorkflows.sol";

contract SpotlightTokenFactory is Ownable, ISpotlightTokenFactory {
    uint256 private _creationFee;
    address private _creationFeeTokenAddress;
    IERC20 private _creationFeeToken;

    SpotlightTokenIPCollection private _tokenIpCollection;
    address private _tokenIpCollectionAddress;

    IStoryDerivativeWorkflows private _storyDerivativeWorkflows;
    address private _storyDerivativeWorkflowsAddress;

    mapping(address => uint256) private _numbersOfTokensCreated;

    constructor(uint256 creationFee_, address creationFeeToken_, address storyDerivativeWorkflows_)
        Ownable(msg.sender)
    {
        _creationFee = creationFee_;
        _creationFeeTokenAddress = creationFeeToken_;
        _creationFeeToken = IERC20(creationFeeToken_);

        _storyDerivativeWorkflowsAddress = storyDerivativeWorkflows_;
        _storyDerivativeWorkflows = IStoryDerivativeWorkflows(storyDerivativeWorkflows_);
    }

    function tokenIpCollection() public view returns (address) {
        return _tokenIpCollectionAddress;
    }

    function setTokenIpCollection(address newTokenIpCollection) external onlyOwner {
        _tokenIpCollectionAddress = newTokenIpCollection;
        _tokenIpCollection = SpotlightTokenIPCollection(newTokenIpCollection);
    }

    function createTokenFee() public view returns (uint256) {
        return _creationFee;
    }

    function setCreateTokenFee(uint256 newFee) external onlyOwner {
        _creationFee = newFee;
    }

    function feeToken() public view returns (address) {
        return _creationFeeTokenAddress;
    }

    function setFeeToken(address newToken) external onlyOwner {
        _creationFeeTokenAddress = newToken;
        _creationFeeToken = IERC20(newToken);
    }

    function storyDerivativeWorkflows() public view returns (address) {
        return _storyDerivativeWorkflowsAddress;
    }

    function setStoryDerivativeWorkflows(address newStoryDerivativeWorkflows) external onlyOwner {
        _storyDerivativeWorkflowsAddress = newStoryDerivativeWorkflows;
        _storyDerivativeWorkflows = IStoryDerivativeWorkflows(newStoryDerivativeWorkflows);
    }

    function calculateTokenAddress(address tokenCreator, string memory tokenName, string memory tokenSymbol)
        external
        view
        returns (address)
    {
        bytes memory bytecode = _tokenCreateBytecode(tokenCreator, tokenName, tokenSymbol);
        bytes32 salt = _salt(tokenCreator);
        bytes32 calculatedHash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));

        return address(uint160(uint256(calculatedHash)));
    }

    function createToken(
        TokenCreationData memory tokenCreationData,
        IntialBuyData memory initialBuyData,
        StoryWorkflowStructs.MakeDerivative calldata derivData,
        StoryWorkflowStructs.IPMetadata calldata ipMetadata,
        StoryWorkflowStructs.SignatureData calldata sigMetadata,
        StoryWorkflowStructs.SignatureData calldata sigRegister
    ) external returns (address tokenAddress, address ipId) {
        tokenAddress = _deploySpotlightToken(tokenCreationData, msg.sender);

        uint256 tokenIpNFTId = _tokenIpCollection.mint(address(this));

        ipId = _storyDerivativeWorkflows.registerIpAndMakeDerivative(
            tokenIpCollection(), tokenIpNFTId, derivData, ipMetadata, sigMetadata, sigRegister
        );

        _tokenIpCollection.transferFrom(address(this), msg.sender, tokenIpNFTId);

        _initalBuy(msg.sender, initialBuyData);
        _chargeCreationFee(msg.sender);
        _numbersOfTokensCreated[msg.sender] += 1;

        emit SpotlightTokenCreated(
            tokenAddress,
            ipId,
            msg.sender,
            tokenCreationData.tokenName,
            tokenCreationData.tokenSymbol,
            tokenIpNFTId,
            initialBuyData.initialBuyAmount,
            initialBuyData.initialBuyRecipient,
            feeToken(),
            createTokenFee(),
            address(this),
            address(0)
        );
    }

    function numberOfTokensCreated(address tokenCreator) public view returns (uint256) {
        return _numbersOfTokensCreated[tokenCreator];
    }

    function claimFee(address recipient) external onlyOwner {
        _creationFeeToken.transfer(recipient, _creationFeeToken.balanceOf(address(this)));
    }

    // @dev Private functions
    function _tokenCreateBytecode(address tokenCreator, string memory tokenName, string memory tokenSymbol)
        internal
        view
        returns (bytes memory)
    {
        bytes memory creationCode = type(SpotlightToken).creationCode;
        bytes memory bytecode =
            abi.encodePacked(creationCode, abi.encode(address(this), tokenCreator, tokenName, tokenSymbol));
        return bytecode;
    }

    function _salt(address account) internal view returns (bytes32) {
        return bytes32(numberOfTokensCreated(account));
    }

    function _deploySpotlightToken(TokenCreationData memory tokenCreationData, address creator)
        internal
        returns (address)
    {
        SpotlightToken token = new SpotlightToken{salt: _salt(creator)}(
            address(this), msg.sender, tokenCreationData.tokenName, tokenCreationData.tokenSymbol
        );
        address tokenAddress = address(token);
        if (tokenAddress != tokenCreationData.predeployedTokenAddress) {
            revert("The address of the created token does not match the predeployed address");
        }
        return tokenAddress;
    }

    function _initalBuy(address tokenAddress, IntialBuyData memory initialBuyData) internal {}

    function _chargeCreationFee(address tokenCreator) internal {
        if (createTokenFee() > 0) {
            _creationFeeToken.transferFrom(tokenCreator, address(this), createTokenFee());
        }
    }
}
