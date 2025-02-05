// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract SpotlightIPCollection is ERC721, Ownable {
    using Strings for uint256;

    bool private _isTransferEnabled = false;
    bool private _isMintEnabled = true;

    uint256 private _nextTokenId;
    string private _defaultTokenURI;
    string public __baseURI;

    modifier onlyTransferEnabled() {
        _checkTransferEnabled();
        _;
    }

    modifier onlyMintEnabled() {
        _checkMintEnabled();
        _;
    }

    constructor() ERC721("Spotlight IP", "SPIP") Ownable(msg.sender) {}

    function totalSupply() external view returns (uint256) {
        return _nextTokenId;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return bytes(_baseURI()).length > 0 ? string.concat(_baseURI(), tokenId.toString()) : _defaultTokenURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        __baseURI = baseURI_;
    }

    function setDefaultTokenURI(string memory defaultTokenURI_) public onlyOwner {
        _defaultTokenURI = defaultTokenURI_;
    }

    function isMintEnabled() public view returns (bool) {
        return _isMintEnabled;
    }

    function _checkMintEnabled() private view {
        if (isMintEnabled() != true) {
            revert("SpotlightIPCollection: mint is disabled");
        }
    }

    function setMintEnabled(bool enabled) public onlyOwner {
        _isMintEnabled = enabled;
    }

    function mint(address to) public onlyOwner onlyMintEnabled returns (uint256) {
        uint256 tokenId = _nextTokenId;
        _mint(to, tokenId);
        _nextTokenId = _nextTokenId + 1;
        return tokenId;
    }

    function mint() public onlyMintEnabled returns (uint256) {
        uint256 tokenId = _nextTokenId;
        _mint(msg.sender, tokenId);
        _nextTokenId = _nextTokenId + 1;
        return tokenId;
    }

    function isTransferEnabled() public view returns (bool) {
        return _isTransferEnabled;
    }

    function _checkTransferEnabled() private view {
        if (isTransferEnabled() != true) {
            revert("SpotlightIPCollection: transfer is disabled");
        }
    }

    function setTransferEnabled(bool enabled) public onlyOwner {
        _isTransferEnabled = enabled;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyTransferEnabled {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyTransferEnabled
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
