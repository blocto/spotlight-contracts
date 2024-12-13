// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ISpotlightToken} from "./ISpotlightToken.sol";

contract SpotlightToken is Ownable, ERC20, ISpotlightToken {
    uint256 public constant BONDIGN_CURVE_SUPPLY = 800_000_000e18;
    uint256 public constant PROTOCOL_TRADING_FEE_PCT = 1; // 1%
    // uint256 public constant MIN_ORDER_SIZE

    address internal _tokenCreator;
    address internal _protocolFeeRecipient;
    address internal _bondingCurve;
    address internal _basedToken; // SUSDC

    constructor(address owner_, address creator_, string memory tokenName_, string memory tokenSymbol_)
        ERC20(tokenName_, tokenSymbol_)
        Ownable(owner_)
    {
        _tokenCreator = creator_;
    }

    // function initialize(
    //     address protocolFeeRecipient_,
    //     address bondingCurve_
    // ) external onlyOwner {
    //     _protocolFeeRecipient = protocolFeeRecipient_;
    //     _bondingCurve = bondingCurve_;
    //     _mint(address(this), BONDIGN_CURVE_SUPPLY);
    // }

    function tokenCreator() public view returns (address) {
        return _tokenCreator;
    }

    function protocolFeeRecipient() public view returns (address) {
        return _protocolFeeRecipient;
    }

    function setProtocolFeeRecipient(address newRecipient) external onlyOwner {
        _protocolFeeRecipient = newRecipient;
    }

    function bondingCurve() public view returns (address) {
        return _bondingCurve;
    }

    function getUSDCBuyQuote(uint256 usdcOrderSize) public view returns (uint256) {
        return 0;
    }

    function getTokenBuyQuote(uint256 tokenOrderSize) public view returns (uint256) {
        return 0;
    }

    function getTokenSellQuote(uint256 tokenOrderSize) public view returns (uint256) {
        return 0;
    }
}
