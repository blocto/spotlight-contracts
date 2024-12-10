// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SpotlightTokenCollection is ERC721, Ownable {
    bool private _isTransferEnabled = false;
    bool private _isMintEnabled = false;
    address private _tokenFactory;

    uint256 private _nextTokenId;
    string private _tokenURI;

    constructor(address tokenFactory_) ERC721("SpotlightTokenCollection", "SpotlightToken") Ownable(msg.sender) {
        _tokenFactory = tokenFactory_;
    }

    modifier onlyTransferEnabled() {
        _checkTransferEnabled();
        _;
    }

    modifier onlyMintEnabled() {
        _checkMintEnabled();
        _;
    }

    /**
     * @dev See {ISpotlightTokenCollection-totalSupply}.
     */
    function totalSupply() external view returns (uint256) {
        return _nextTokenId;
    }

    /**
     * @dev See {ISpotlightTokenCollection-setTokenURI}.
     * @notice onlyOwner
     */
    function setTokenURI(string memory tokenURI_) public onlyOwner {
        _tokenURI = tokenURI_;
    }

    /**
     * @dev See {ISpotlightTokenCollection-isMintEnabled}.
     */
    function isMintEnabled() public view returns (bool) {
        return _isMintEnabled;
    }

    /**
     * @dev See {ISpotlightTokenCollection-setMintEnabled}.
     * @notice onlyOwner
     */
    function setMintEnabled(bool enabled) public onlyOwner {
        _isMintEnabled = enabled;
    }

    /**
     * @dev See {ISpotlightTokenCollection-tokenFactory}.
     */
    function tokenFactory() public view returns (address) {
        return _tokenFactory;
    }

    /**
     * @dev See {ISpotlightTokenCollection-setTokenFactory}.
     * @notice onlyOwner
     */
    function setTokenFactory(address newTokenFactory) external onlyOwner {
        _tokenFactory = newTokenFactory;
    }

    /**
     * @dev See {ISpotlightTokenCollection-isTransferEnabled}.
     */
    function isTransferEnabled() public view returns (bool) {
        return _isTransferEnabled;
    }

    /**
     * @dev See {ISpotlightTokenCollection-setTransferEnabled}.
     * @notice onlyOwner
     */
    function setTransferEnabled(bool enabled) public onlyOwner {
        _isTransferEnabled = enabled;
    }

    /**
     * @dev See {ISpotlightTokenCollection-mint}.
     * @notice onlyOwner or tokenFactory
     */
    function mint(address to) public onlyMintEnabled returns (uint256) {
        if (msg.sender != owner() && msg.sender != tokenFactory()) {
            revert("SpotlightTokenCollection: only owner or token factory can mint");
        }

        uint256 tokenId = _nextTokenId;
        _mint(to, tokenId);
        _nextTokenId = _nextTokenId + 1;
        return tokenId;
    }

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return _tokenURI;
    }

    /**
     * @dev See {ERC721-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return _tokenURI;
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override onlyTransferEnabled {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyTransferEnabled
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _checkMintEnabled() private view {
        if (isMintEnabled() != true) {
            revert("SpotlightTokenCollection: mint is disabled");
        }
    }

    function _checkTransferEnabled() private view {
        if (isTransferEnabled() != true) {
            revert("SpotlightTokenCollection: transfer is disabled");
        }
    }
}
