// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {BeaconProxyStorage} from "../beacon-proxy/BeaconProxyStorage.sol";
import {BeaconProxy} from "../beacon-proxy/BeaconProxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ISpotlightTokenFactory} from "./ISpotlightTokenFactory.sol";
import {ISpotlightToken} from "../spotlight-token/ISpotlightToken.sol";
import {ISpotlightTokenIPCollection} from "../spotlight-token-collection/ISpotlightTokenIPCollection.sol";
import {StoryWorkflowStructs} from "./story-workflow-interfaces/StoryWorkflowStructs.sol";
import {IStoryDerivativeWorkflows} from "./story-workflow-interfaces/IStoryDerivativeWorkflows.sol";
import {SpotlightTokenFactoryStorage} from "./SpotlightTokenFactoryStorage.sol";
import {ISpotlightBondingCurve} from "../spotlight-bonding-curve/ISpotlightBondingCurve.sol";
import {MarketType} from "../spotlight-token/ISpotlightToken.sol";

contract SpotlightTokenFactory is BeaconProxyStorage, SpotlightTokenFactoryStorage, ISpotlightTokenFactory {
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
        address tokenIpCollection_,
        address tokenBeacon_,
        address bondingCurve_,
        address baseToken_,
        address storyDerivativeWorkflows_,
        address piperXRouter_,
        address piperXFactory_
    ) external {
        if (isInitialized()) {
            revert("SpotlightTokenFactory: Already initialized");
        }
        _owner = owner_;
        _creationFee = creationFee_;
        _tokenIpCollection = tokenIpCollection_;
        _tokenBeacon = tokenBeacon_;
        _bondingCurve = bondingCurve_;
        _baseToken = baseToken_;
        _storyDerivativeWorkflows = storyDerivativeWorkflows_;

        _isInitialized = true;
        _piperXRouter = piperXRouter_;
        _piperXFactory = piperXFactory_;
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
        StoryWorkflowStructs.SignatureData calldata sigRegister,
        address specificAddress
    ) external payable needInitialized returns (address tokenAddress, address ipId) {
        tokenAddress = _deploySpotlightToken(tokenCreationData, msg.sender, specificAddress);

        ISpotlightTokenIPCollection(_tokenIpCollection).mint(msg.sender, tokenCreationData.tokenIpNFTId);

        ipId = IStoryDerivativeWorkflows(_storyDerivativeWorkflows).registerIpAndMakeDerivative(
            tokenIpCollection(), tokenCreationData.tokenIpNFTId, derivData, ipMetadata, sigMetadata, sigRegister
        );

        _distributeFeesAndInitialBuy(tokenAddress, initialBuyData);
        _numbersOfTokensCreated[msg.sender] += 1;

        emit SpotlightTokenCreated(
            tokenAddress,
            ipId,
            msg.sender,
            IERC20Metadata(tokenAddress).name(),
            IERC20Metadata(tokenAddress).symbol(),
            tokenCreationData.tokenIpNFTId,
            initialBuyData.initialBuyAmount,
            initialBuyData.initialBuyRecipient,
            createTokenFee(),
            address(this),
            bondingCurve()
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
        (bool success,) = recipient.call{value: address(this).balance}("");
        require(success, "SpotlightTokenFactory: Failed to claim fee");
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
        return keccak256(abi.encodePacked(account, numberOfTokensCreated(account)));
    }

    function _deploySpotlightToken(TokenCreationData memory tokenCreationData, address creator, address specificAddress)
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
            tokenCreationData.tokenSymbol,
            _piperXRouter,
            _piperXFactory,
            specificAddress
        );
        if (tokenAddress != tokenCreationData.predeployedTokenAddress) {
            revert("The address of the created token does not match the predeployed address");
        }
        return tokenAddress;
    }

    function _distributeFeesAndInitialBuy(address tokenAddress, IntialBuyData memory initialBuyData) internal {
        uint256 totalRequired = initialBuyData.initialBuyAmount + createTokenFee();
        require(msg.value >= totalRequired, "SpotlightTokenFactory: Insufficient total amount");

        _initalBuy(tokenAddress, initialBuyData);
        _chargeCreationFee(msg.sender, totalRequired);
    }

    function _initalBuy(address tokenAddress, IntialBuyData memory initialBuyData) internal {
        if (initialBuyData.initialBuyAmount == 0) return;

        ISpotlightToken(tokenAddress).buyWithIP{value: initialBuyData.initialBuyAmount}(
            initialBuyData.initialBuyRecipient, 0, MarketType.BONDING_CURVE
        );
    }

    function _chargeCreationFee(address tokenCreator, uint256 totalRequired) internal {
        uint256 fee = createTokenFee();
        if (fee == 0) return;

        uint256 excess = msg.value - totalRequired;
        if (excess == 0) return;

        (bool success,) = tokenCreator.call{value: excess}("");
        require(success, "SpotlightTokenFactory: Failed to return excess fee");
    }
}
