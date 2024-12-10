// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ISpotlightTokenFactory} from "./ISpotlightTokenFactory.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SpotlightToken} from "../spotlight-token/SpotlightToken.sol";
import {SpotlightTokenCollection} from "../spotlight-token-collection/SpotlightTokenCollection.sol";

contract SpotlightTokenFactory is Ownable, ISpotlightTokenFactory {
    uint256 private _createTokenFee = 0;
    address private _feeTokenAddress;
    IERC20 private _feeToken;

    SpotlightTokenCollection private _tokenCollection;
    address private _tokenCollectionAddress;

    mapping(address => uint256) private _numbersOfTokensCreated;

    constructor(uint256 createTokenFee_, address feeToken_) Ownable(msg.sender) {
        _createTokenFee = createTokenFee_;
        _feeTokenAddress = feeToken_;
        _feeToken = IERC20(feeToken_);
        _tokenCollection = new SpotlightTokenCollection(
            msg.sender, // owner
            address(this) // token factory
        );
        _tokenCollectionAddress = address(_tokenCollection);
    }

    function tokenCollection() public view returns (address) {
        return _tokenCollectionAddress;
    }

    function setTokenCollection(address newTokenCollection) external onlyOwner {
        _tokenCollectionAddress = newTokenCollection;
        _tokenCollection = SpotlightTokenCollection(newTokenCollection);
    }

    function createTokenFee() public returns (uint256) {
        return _createTokenFee;
    }

    function setCreateTokenFee(uint256 newFee) external onlyOwner {
        _createTokenFee = newFee;
    }

    function feeToken() public returns (address) {
        return _feeTokenAddress;
    }

    function setFeeToken(address newToken) external onlyOwner {
        _feeTokenAddress = newToken;
        _feeToken = IERC20(newToken);
    }

    function numberOfTokensCreated(address tokenCreator) external view returns (uint256) {
        return _numbersOfTokensCreated[tokenCreator];
    }

    function calculateTokenAddress(address tokenCreator, string memory tokenName, string memory tokenSymbol)
        external
        returns (address)
    {
        bytes memory bytecode = _tokenCreateBytecode(tokenCreator, tokenName, tokenSymbol);
        bytes32 salt = _slat(tokenCreator);
        bytes32 calculatedHash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));

        return address(uint160(uint256(calculatedHash)));
    }

    function createToken(string memory tokenName_, string memory tokenSymbol_, address predeployedTokenAddress)
        external
        returns (address)
    {
        // todo: charge fee

        // deply spotlight token
        SpotlightToken token =
            new SpotlightToken{salt: _slat(msg.sender)}(address(this), msg.sender, tokenName_, tokenSymbol_);
        if (address(token) != predeployedTokenAddress) {
            revert("The address of the created token does not match the predeployed address");
        }

        // mint spotlight token nft
        uint256 spotlightTokenNFTId = _tokenCollection.mint(msg.sender);

        // register ip and set meta data

        // return and emit event

        _numbersOfTokensCreated[msg.sender] += 1;
        return address(token);
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
        return bytes32(_numbersOfTokensCreated[account]);
    }
}
