// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ISpotlightTokenIPCollection} from "./ISpotlightTokenIPCollection.sol";

contract SpotlightTokenIPCollection is Ownable, ERC721, ISpotlightTokenIPCollection {
    using Strings for uint256;

    uint256 private _totalSupply;
    bool private _isTransferEnabled = false;
    bool private _isMintEnabled = false;
    address private _tokenFactory;
    string private _defaultTokenURI = "ipfs://bafkreibqge4t7rsppnarffvrzlfph5rk5ajvupa4oyk4v2h3ieqccty4ye";
    string public __baseURI;

    constructor(address tokenFactory_) Ownable(msg.sender) ERC721("Spotlight Token IP", "SPTIP") {
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
        return _totalSupply;
    }

    /**
     * @dev See {ISpotlightTokenCollection-setBaseURI}.
     * @notice onlyOwner
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        __baseURI = baseURI_;
    }

    /**
     * @dev See {ISpotlightTokenCollection-setDefaultTokenURI}.
     * @notice onlyOwner
     */
    function setDefaultTokenURI(string memory defaultTokenURI_) public onlyOwner {
        _defaultTokenURI = defaultTokenURI_;
    }

    /**
     * @dev See {ISpotlightTokenCollection-isMintEnabled}.
     * @notice the owner and the token factory can mint regardless of this setting.
     */
    function isMintEnabled() public view returns (bool) {
        if (msg.sender == owner() || msg.sender == tokenFactory()) {
            return true;
        }
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
     * @notice the owner and the token factory can transfer tokens regardless of this setting.
     */
    function isTransferEnabled() public view returns (bool) {
        if (msg.sender == owner() || msg.sender == tokenFactory()) {
            return true;
        }
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
    function mint(address to, uint256 tokenId) public onlyMintEnabled {
        if (_ownerOf(tokenId) != address(0)) {
            revert("SpotlightTokenCollection: token already minted");
        }
        _totalSupply += 1;
        _mint(to, tokenId);
    }

    /**
     * @dev See {ERC721-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        return bytes(_baseURI()).length > 0 ? string.concat(_baseURI(), tokenId.toString()) : _defaultTokenURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
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
