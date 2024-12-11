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

        _tokenIpCollection = new SpotlightTokenIPCollection(msg.sender, address(this));
        _tokenIpCollectionAddress = address(_tokenIpCollection);

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

    function calculateTokenAddress(address tokenCreator, string memory tokenName, string memory tokenSymbol)
        external
        view
        returns (address)
    {
        bytes memory bytecode = _tokenCreateBytecode(tokenCreator, tokenName, tokenSymbol);
        bytes32 salt = _slat(tokenCreator);
        bytes32 calculatedHash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));

        return address(uint160(uint256(calculatedHash)));
    }

    function createToken(
        string memory tokenName_,
        string memory tokenSymbol_,
        address predeployedTokenAddress,
        uint256 initialBuyAmount,
        address initialBuyRecipient,
        StoryWorkflowStructs.MakeDerivative calldata derivData,
        StoryWorkflowStructs.IPMetadata calldata ipMetadata,
        StoryWorkflowStructs.SignatureData calldata sigMetadata,
        StoryWorkflowStructs.SignatureData calldata sigRegister
    ) external returns (address tokenAddress, address ipId) {
        address tokenCreator = msg.sender;
        address tokenOwner = address(this);

        // deply spotlight token
        SpotlightToken token =
            new SpotlightToken{salt: _slat(tokenCreator)}(tokenOwner, tokenCreator, tokenName_, tokenSymbol_);
        tokenAddress = address(token);
        if (tokenAddress != predeployedTokenAddress) {
            revert("The address of the created token does not match the predeployed address");
        }

        // mint spotlight token nft
        uint256 tokenIpNFTId = _tokenIpCollection.mint(address(this));

        // register ip and set meta data
        ipId = _storyDerivativeWorkflows.registerIpAndMakeDerivative(
            tokenIpCollection(), tokenIpNFTId, derivData, ipMetadata, sigMetadata, sigRegister
        );

        // transfer nft to creator
        _tokenIpCollection.transferFrom(address(this), tokenCreator, tokenIpNFTId);

        // todo: charge fee and initial buy
        if (createTokenFee() > 0) {
            _creationFeeToken.transferFrom(tokenCreator, address(this), createTokenFee());
        }

        // emit event
        _numbersOfTokensCreated[tokenCreator] += 1;

        emit SpotlightTokenCreated(
            tokenAddress,
            ipId,
            tokenCreator,
            tokenName_,
            tokenSymbol_,
            tokenIpNFTId,
            initialBuyAmount,
            initialBuyRecipient,
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

    function _slat(address account) internal view returns (bytes32) {
        return bytes32(numberOfTokensCreated(account));
    }
}
