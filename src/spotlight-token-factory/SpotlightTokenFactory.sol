// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ISpotlightTokenFactory} from "./ISpotlightTokenFactory.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SpotlightToken} from "../spotlight-token/SpotlightToken.sol";

contract SpotlightTokenFactory is Ownable, ISpotlightTokenFactory {
    mapping(address => uint256) public _slats;

    constructor() Ownable(msg.sender) {}

    function calculateTokenAddress(
        address tokenCreator,
        string memory tokenName,
        string memory tokenSymbol
    ) external returns (address) {
        // bytecode
        bytes memory creationCode = type(SpotlightToken).creationCode;
        bytes memory bytecode = abi.encodePacked(
            creationCode,
            abi.encode(address(this), tokenCreator, tokenName, tokenSymbol)
        );

        // salt
        bytes32 salt = bytes32(_slats[tokenCreator]);
        bytes32 calculatedHash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );

        return address(uint160(uint256(calculatedHash)));
    }

    function numberOfTokensCreated(
        address tokenCreator
    ) external view returns (uint256) {
        return _slats[tokenCreator];
    }

    function createToken(
        string memory tokenName_,
        string memory tokenSymbol_
    ) external returns (address) {
        SpotlightToken token = new SpotlightToken{
            salt: bytes32(_slats[msg.sender])
        }(address(this), msg.sender, tokenName_, tokenSymbol_);
        return address(token);
    }
}
