// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IMinimalIPAccount} from "../interfaces/IMinimalIPAccount.sol";
import {ISpotlightTokenFactory} from "./ISpotlightTokenFactory.sol";
import {ISpotlightToken} from "../spotlight-token/ISpotlightToken.sol";
import {ISpotlightTokenIPCollection} from "../spotlight-token-collection/ISpotlightTokenIPCollection.sol";
import {StoryWorkflowStructs} from "./story-workflow-interfaces/StoryWorkflowStructs.sol";
import {IStoryDerivativeWorkflows} from "./story-workflow-interfaces/IStoryDerivativeWorkflows.sol";
import {SpotlightTokenFactoryStorage} from "./SpotlightTokenFactoryStorage.sol";
import {ISpotlightBondingCurve} from "../spotlight-bonding-curve/ISpotlightBondingCurve.sol";
import {MarketType} from "../spotlight-token/ISpotlightToken.sol";

contract SpotlightTokenFactory is OwnableUpgradeable, SpotlightTokenFactoryStorage, ISpotlightTokenFactory {
    modifier needInitialized() {
        _checkIsInitialized();
        _;
    }

    /**
     * @dev See {ISpotlightTokenFactory-isInitialized}.
     */
    function isInitialized() public view returns (bool) {
        return _getInitializedVersion() == 1;
    }

    /**
     * @dev See {ISpotlightTokenFactory-initialize}.
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
    ) external initializer {
        __Ownable_init(owner_);
        _creationFee = creationFee_;
        _tokenIpCollection = tokenIpCollection_;
        _tokenImplementation = tokenImplementation_;
        _bondingCurve = bondingCurve_;
        _storyDerivativeWorkflows = storyDerivativeWorkflows_;
        _piperXRouter = piperXRouter_;
        _piperXFactory = piperXFactory_;
        _rewardsVault = rewardsVault_;
    }

    /**
     * @dev See {ISpotlightTokenFactory-creationFee}.
     */
    function createTokenFee() public view returns (uint256) {
        return _creationFee;
    }

    /**
     * @dev See {ISpotlightTokenFactory-setCreateTokenFee}.
     */
    function setCreateTokenFee(uint256 newFee) external needInitialized onlyOwner {
        _creationFee = newFee;
    }

    /**
     * @dev See {ISpotlightTokenFactory-tokenIpCollection}.
     */
    function tokenIpCollection() public view returns (address) {
        return _tokenIpCollection;
    }

    /**
     * @dev See {ISpotlightTokenFactory-tokenImplementation}.
     */
    function tokenImplementation() public view returns (address) {
        return _tokenImplementation;
    }

    /**
     * @dev See {ISpotlightTokenFactory-setTokenImplementation}.
     */
    function setTokenImplementation(address newTokenImplementation) external needInitialized onlyOwner {
        _tokenImplementation = newTokenImplementation;
    }

    /**
     * @dev See {ISpotlightTokenFactory-bondingCurve}.
     */
    function bondingCurve() public view returns (address) {
        return _bondingCurve;
    }

    /**
     * @dev See {ISpotlightTokenFactory-setBondingCurve}.
     */
    function setBondingCurve(address newBondingCurve) external needInitialized onlyOwner {
        _bondingCurve = newBondingCurve;
    }

    /**
     * @dev See {ISpotlightTokenFactory-storyDerivativeWorkflows}.
     */
    function storyDerivativeWorkflows() public view returns (address) {
        return _storyDerivativeWorkflows;
    }

    /**
     * @dev See {ISpotlightTokenFactory-piperXRouter}.
     */
    function piperXRouter() public view returns (address) {
        return _piperXRouter;
    }

    /**
     * @dev See {ISpotlightTokenFactory-piperXFactory}.
     */
    function piperXFactory() public view returns (address) {
        return _piperXFactory;
    }

    /**
     * @dev See {ISpotlightTokenFactory-rewardsVault}.
     */
    function rewardsVault() public view returns (address) {
        return _rewardsVault;
    }

    /**
     * @dev See {ISpotlightTokenFactory-calculateTokenAddress}.
     */
    function calculateTokenAddress(address tokenCreator) external view returns (address) {
        bytes32 salt = _salt(tokenCreator);
        return Clones.predictDeterministicAddress(_tokenImplementation, salt, address(this));
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
    ) external payable needInitialized returns (address tokenAddress, address ipId) {
        require(derivData.parentIpIds.length > 0, "SpotlightTokenFactory: Parent IP ID is required");
        address parentIPAccount = derivData.parentIpIds[0];
        require(_checkIsValidIPAccount(parentIPAccount), "SpotlightTokenFactory: Parent IP Account is not valid");
        tokenAddress = _deploySpotlightToken(tokenCreationData, msg.sender, parentIPAccount);

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
     * @dev See {ISpotlightTokenFactory-numberOfTokensCreated}.
     */
    function numberOfTokensCreated(address tokenCreator) public view returns (uint256) {
        return _numbersOfTokensCreated[tokenCreator];
    }

    /**
     * @dev See {ISpotlightTokenFactory-claimFee}.
     */
    function claimFee(address recipient) external onlyOwner {
        (bool success,) = recipient.call{value: address(this).balance}("");
        require(success, "SpotlightTokenFactory: Failed to claim fee");
    }

    receive() external payable {}

    // @dev - private functions
    function _checkIsInitialized() internal view {
        if (!isInitialized()) {
            revert("SpotlightTokenFactory: Not initialized");
        }
    }

    function _salt(address account) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(account, numberOfTokensCreated(account)));
    }

    function _deploySpotlightToken(TokenCreationData memory tokenCreationData, address creator, address ipAccount)
        internal
        returns (address)
    {
        address tokenAddress = Clones.cloneDeterministic(_tokenImplementation, _salt(creator));
        ISpotlightToken(tokenAddress).initialize(
            tokenCreationData.tokenName,
            tokenCreationData.tokenSymbol,
            creator,
            _bondingCurve,
            address(this),
            ipAccount,
            _rewardsVault,
            _piperXRouter,
            _piperXFactory
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

    function _checkIsValidIPAccount(address ipAccount) internal view returns (bool) {
        (, address tokenContract,) = IMinimalIPAccount(ipAccount).token();
        return tokenContract != address(0);
    }
}
