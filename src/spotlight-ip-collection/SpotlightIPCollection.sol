// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ERC721} from "../../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract SpotlightIPCollection is ERC721, Ownable {
    bool private _isTransferEnabled = false;
    bool private _isMintEnabled = false;

    uint256 private _nextTokenId;
    string private _tokenURI;

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
        return _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return _tokenURI;
    }

    function setTokenURI(string memory tokenURI_) public onlyOwner {
        _tokenURI = tokenURI_;
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
