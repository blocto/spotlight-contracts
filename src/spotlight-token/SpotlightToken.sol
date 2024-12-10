// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SpotlightToken is ERC20, Ownable {
    address private _creator;

    constructor(address owner_, address creator_, string memory tokenName_, string memory tokenSymbol_)
        ERC20(tokenName_, tokenSymbol_)
        Ownable(owner_)
    {
        _creator = creator_;
    }
}
