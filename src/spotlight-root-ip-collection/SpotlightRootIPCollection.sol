// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract SpotlightRootIPCollection is ERC721, Ownable {
    using Strings for uint256;

    bool private _isTransferEnabled = false;

    uint256 private _nextTokenId;
    string private _tokenURI = "ipfs://bafkreidsyc4pkxkk7io56uf5hhnvkx2n6ukua4xjg42dsv5n7y2hbb3h3u";

    modifier onlyTransferEnabled() {
        _checkTransferEnabled();
        _;
    }

    constructor() ERC721("Spotlight Root IP", "SPRIP") Ownable(msg.sender) {}

    function totalSupply() external view returns (uint256) {
        return _nextTokenId;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return _tokenURI;
    }

    function setTokenURI(string memory tokenURI_) public onlyOwner {
        _tokenURI = tokenURI_;
    }

    function mint() public onlyOwner returns (uint256) {
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
            revert("SpotlightRootIPCollection: transfer is disabled");
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
