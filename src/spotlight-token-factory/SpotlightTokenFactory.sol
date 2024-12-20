// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {BeaconProxyStorage} from "../beacon-proxy/BeaconProxyStorage.sol";
import {BeaconProxy} from "../beacon-proxy/BeaconProxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISpotlightTokenFactory} from "./ISpotlightTokenFactory.sol";
import {ISpotlightToken} from "../spotlight-token/ISpotlightToken.sol";
import {ISpotlightTokenIPCollection} from "../spotlight-token-collection/ISpotlightTokenIPCollection.sol";
import {StoryWorkflowStructs} from "./story-workflow-interfaces/StoryWorkflowStructs.sol";
import {IStoryDerivativeWorkflows} from "./story-workflow-interfaces/IStoryDerivativeWorkflows.sol";
import {SpotlightTokenFactoryStorage} from "./SpotlightTokenFactoryStorage.sol";
import {ISpotlightBondingCurve} from "../spotlight-bonding-curve/ISpotlightBondingCurve.sol";

contract SpotlightTokenFactory is BeaconProxyStorage, SpotlightTokenFactoryStorage, ISpotlightTokenFactory {
    constructor() {}

    modifier needInitialized() {
        _checkIsInitialized();
        _;
    }

    modifier onlyOwner() {
        _checkIsOwner();
        _;
    }

    /**
     * @dev See {ISpotlightTokenFactory-isInitialized}.
     */
    function isInitialized() public view returns (bool) {
        return _isInitialized;
    }

    /**
     * @dev See {ISpotlightTokenFactory-initialize}.
     */
    function initialize(
        address owner_,
        uint256 creationFee_,
        address creationFeeToken_,
        address tokenBeacon_,
        address bondingCurve_,
        address baseToken_,
        address storyDerivativeWorkflows_
    ) external {
        if (isInitialized()) {
            revert("SpotlightTokenFactory: Already initialized");
        }
        _owner = owner_;
        _creationFee = creationFee_;
        _creationFeeToken = creationFeeToken_;
        _tokenBeacon = tokenBeacon_;
        _bondingCurve = bondingCurve_;
        _baseToken = baseToken_;
        _storyDerivativeWorkflows = storyDerivativeWorkflows_;

        _isInitialized = true;
    }

    /**
     * @dev See {ISpotlightTokenFactory-owner}.
     */
    function owner() public view needInitialized returns (address) {
        return _owner;
    }

    /**
     * @dev See {ISpotlightTokenFactory-tokenIpCollection}.
     */
    function tokenIpCollection() public view needInitialized returns (address) {
        return _tokenIpCollection;
    }

    /**
     * @dev See {ISpotlightTokenFactory-setTokenIpCollection}.
     */
    function setTokenIpCollection(address newTokenIpCollection) external needInitialized onlyOwner {
        _tokenIpCollection = newTokenIpCollection;
    }

    /**
     * @dev See {ISpotlightTokenFactory-bondingCurve}.
     */
    function tokenBeacon() public view needInitialized returns (address) {
        return _tokenBeacon;
    }

    /**
     * @dev See {ISpotlightTokenFactory-setTokenBeacon}.
     */
    function setTokenBeacon(address newTokenBeacon) external needInitialized onlyOwner {
        _tokenBeacon = newTokenBeacon;
    }

    /**
     * @dev See {ISpotlightTokenFactory-creationFee}.
     */
    function createTokenFee() public view needInitialized returns (uint256) {
        return _creationFee;
    }

    /**
     * @dev See {ISpotlightTokenFactory-setCreateTokenFee}.
     */
    function setCreateTokenFee(uint256 newFee) external needInitialized onlyOwner {
        _creationFee = newFee;
    }

    /**
     * @dev See {ISpotlightTokenFactory-feeToken}.
     */
    function feeToken() public view needInitialized returns (address) {
        return _creationFeeToken;
    }

    /**
     * @dev See {ISpotlightTokenFactory-setFeeToken}.
     */
    function setFeeToken(address newToken) external needInitialized onlyOwner {
        _creationFeeToken = newToken;
    }

    /**
     * @dev See {ISpotlightTokenFactory-storyDerivativeWorkflows}.
     */
    function storyDerivativeWorkflows() public view needInitialized returns (address) {
        return _storyDerivativeWorkflows;
    }

    /**
     * @dev See {ISpotlightTokenFactory-setStoryDerivativeWorkflows}.
     */
    function setStoryDerivativeWorkflows(address newStoryDerivativeWorkflows) external needInitialized onlyOwner {
        _storyDerivativeWorkflows = newStoryDerivativeWorkflows;
    }

    /**
     * @dev See {ISpotlightTokenFactory-baseToken}.
     */
    function baseToken() public view needInitialized returns (address) {
        return _baseToken;
    }

    /**
     * @dev See {ISpotlightTokenFactory-setBaseToken}.
     */
    function setBaseToken(address newBaseToken) external needInitialized onlyOwner {
        _baseToken = newBaseToken;
    }

    /**
     * @dev See {ISpotlightTokenFactory-bondingCurve}.
     */
    function bondingCurve() public view needInitialized returns (address) {
        return _bondingCurve;
    }

    /**
     * @dev See {ISpotlightTokenFactory-setBondingCurve}.
     */
    function setBindingCurve(address newBondingCurve) external needInitialized onlyOwner {
        _bondingCurve = newBondingCurve;
    }

    /**
     * @dev See {ISpotlightTokenFactory-calculateTokenAddress}.
     */
    function calculateTokenAddress(address tokenCreator) external view needInitialized returns (address) {
        bytes memory bytecode = _tokenCreateBytecode();
        bytes32 salt = _salt(tokenCreator);
        bytes32 calculatedHash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));

        return address(uint160(uint256(calculatedHash)));
    }

    /**
     * @dev See {ISpotlightTokenFactory-createToken}.
     */
    function createToken(
        TokenCreationData memory tokenCreationData,
        IntialBuyData memory initialBuyData,
        StoryWorkflowStructs.MakeDerivative calldata derivData,
        StoryWorkflowStructs.IPMetadata calldata ipMetadata,
        StoryWorkflowStructs.SignatureData calldata sigMetadata,
        StoryWorkflowStructs.SignatureData calldata sigRegister
    ) external needInitialized returns (address tokenAddress, address ipId) {
        tokenAddress = _deploySpotlightToken(tokenCreationData, msg.sender);

        ISpotlightTokenIPCollection(_tokenIpCollection).mint(msg.sender, tokenCreationData.tokenIpNFTId);

        ipId = IStoryDerivativeWorkflows(_storyDerivativeWorkflows).registerIpAndMakeDerivative(
            tokenIpCollection(), tokenCreationData.tokenIpNFTId, derivData, ipMetadata, sigMetadata, sigRegister
        );

        _initalBuy(msg.sender, initialBuyData);
        _chargeCreationFee(msg.sender);
        _numbersOfTokensCreated[msg.sender] += 1;

        emit SpotlightTokenCreated(
            tokenAddress,
            ipId,
            msg.sender,
            tokenCreationData.tokenName,
            tokenCreationData.tokenSymbol,
            tokenCreationData.tokenIpNFTId,
            initialBuyData.initialBuyAmount,
            initialBuyData.initialBuyRecipient,
            feeToken(),
            createTokenFee(),
            address(this),
            address(0)
        );
    }

    /**
     * @dev See {ISpotlightTokenFactory-getInitialBuyTokenQuote}.
     */
    function getInitialBuyTokenQuote(uint256 tokensOut) external view needInitialized returns (uint256) {
        return ISpotlightBondingCurve(_bondingCurve).getTargetTokenBuyQuote(0, tokensOut);
    }

    /**
     * @dev See {ISpotlightTokenFactory-numberOfTokensCreated}.
     */
    function numberOfTokensCreated(address tokenCreator) public view needInitialized returns (uint256) {
        return _numbersOfTokensCreated[tokenCreator];
    }

    /**
     * @dev See {ISpotlightTokenFactory-claimFee}.
     */
    function claimFee(address recipient) external onlyOwner {
        IERC20(_creationFeeToken).transfer(recipient, IERC20(_creationFeeToken).balanceOf(address(this)));
    }

    // @dev - private functions
    function _checkIsInitialized() internal view {
        if (!isInitialized()) {
            revert("SpotlightTokenFactory: Not initialized");
        }
    }

    function _checkIsOwner() internal view {
        require(msg.sender == _owner, "SpotlightTokenFactory: Not owner");
    }

    function _tokenCreateBytecode() internal view returns (bytes memory) {
        bytes memory creationCode = type(BeaconProxy).creationCode;
        bytes memory bytecode = abi.encodePacked(creationCode, abi.encode(_tokenBeacon));
        return bytecode;
    }

    function _salt(address account) internal view returns (bytes32) {
        return bytes32(numberOfTokensCreated(account));
    }

    function _deploySpotlightToken(TokenCreationData memory tokenCreationData, address creator)
        internal
        returns (address)
    {
        BeaconProxy tokenProxy = new BeaconProxy{salt: _salt(creator)}(_tokenBeacon);
        address tokenAddress = address(tokenProxy);
        ISpotlightToken(tokenAddress).initialize(
            owner(),
            creator,
            _bondingCurve,
            _baseToken,
            owner(),
            tokenCreationData.tokenName,
            tokenCreationData.tokenSymbol
        );
        if (tokenAddress != tokenCreationData.predeployedTokenAddress) {
            revert("The address of the created token does not match the predeployed address");
        }
        return tokenAddress;
    }

    function _initalBuy(address tokenAddress, IntialBuyData memory initialBuyData) internal {
        if (initialBuyData.initialBuyAmount > 0) {
            ISpotlightToken(tokenAddress).buyToken(
                initialBuyData.initialBuyAmount, initialBuyData.initialBuyRecipient, type(uint256).max
            );
        }
    }

    function _chargeCreationFee(address tokenCreator) internal {
        if (createTokenFee() > 0) {
            IERC20(_creationFeeToken).transferFrom(tokenCreator, address(this), createTokenFee());
        }
    }
}
