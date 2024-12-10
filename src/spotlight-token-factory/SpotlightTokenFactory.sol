// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ISpotlightTokenFactory} from "./ISpotlightTokenFactory.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SpotlightToken} from "../spotlight-token/SpotlightToken.sol";

contract SpotlightTokenFactory is Ownable, ISpotlightTokenFactory {
    uint256 private _CREATE_TOKNE_FEE;
    mapping(address => uint256) private _numbersOfTokensCreated;

    constructor() Ownable(msg.sender) {}

    function calculateTokenAddress(address tokenCreator, string memory tokenName, string memory tokenSymbol)
        external
        returns (address)
    {
        bytes memory bytecode = _tokenCreateBytecode(tokenCreator, tokenName, tokenSymbol);
        bytes32 salt = _slat(tokenCreator);
        bytes32 calculatedHash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));

        return address(uint160(uint256(calculatedHash)));
    }

    function numberOfTokensCreated(address tokenCreator) external view returns (uint256) {
        return _numbersOfTokensCreated[tokenCreator];
    }

    function createToken(string memory tokenName_, string memory tokenSymbol_, address predeployedTokenAddress)
        external
        returns (address)
    {
        SpotlightToken token =
            new SpotlightToken{salt: _slat(msg.sender)}(address(this), msg.sender, tokenName_, tokenSymbol_);
        if (address(token) != predeployedTokenAddress) {
            revert("The address of the created token does not match the predeployed address");
        }

        _numbersOfTokensCreated[msg.sender] += 1;
        return address(token);
    }

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
