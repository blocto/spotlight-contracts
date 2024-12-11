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
    uint256 private _createTokenFee;
    address private _feeTokenAddress;
    IERC20 private _feeToken;

    SpotlightTokenIPCollection private _tokenIpCollection;
    address private _tokenIpCollectionAddress;

    IStoryDerivativeWorkflows private _storyDerivativeWorkflows;
    address private _storyDerivativeWorkflowsAddress;

    mapping(address => uint256) private _numbersOfTokensCreated;

    constructor(uint256 createTokenFee_, address feeToken_, address storyDerivativeWorkflows_) Ownable(msg.sender) {
        _createTokenFee = createTokenFee_;
        _feeTokenAddress = feeToken_;
        _feeToken = IERC20(feeToken_);

        _tokenIpCollection = new SpotlightTokenIPCollection(
            msg.sender, // owner
            address(this) // token factory
        );
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
        return _createTokenFee;
    }

    function setCreateTokenFee(uint256 newFee) external onlyOwner {
        _createTokenFee = newFee;
    }

    function feeToken() public view returns (address) {
        return _feeTokenAddress;
    }

    function setFeeToken(address newToken) external onlyOwner {
        _feeTokenAddress = newToken;
        _feeToken = IERC20(newToken);
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
    ) external returns (address) {
        // deply spotlight token
        SpotlightToken token =
            new SpotlightToken{salt: _slat(msg.sender)}(address(this), msg.sender, tokenName_, tokenSymbol_);
        if (address(token) != predeployedTokenAddress) {
            revert("The address of the created token does not match the predeployed address");
        }

        // mint spotlight token nft
        uint256 tokenIpNFTId = _tokenIpCollection.mint(address(this));

        // register ip and set meta data

        // return and emit event
        _numbersOfTokensCreated[msg.sender] += 1;

        // todo: charge fee and initial buy

        return address(token);
    }

    function numberOfTokensCreated(address tokenCreator) public view returns (uint256) {
        return _numbersOfTokensCreated[tokenCreator];
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
