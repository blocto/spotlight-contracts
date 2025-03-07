// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import {SpotlightTokenIPCollection} from "../src/spotlight-token-collection/SpotlightTokenIPCollection.sol";

contract SpotlightTokenIPCollectionTest is Test {
    address private _owner;
    address private _tokenFactoryAddr;

    SpotlightTokenIPCollection private _tokenIpCollection;
    address private _tokenIpCollectionAddr;

    string private defaultTokenURI = "ipfs://bafkreifl7ifonbfll7nn423tm5s7lvcw7jc6qgimcc2izef4foo47srt2e";
    string private newTokenURI = "https://example.com/new-token/";

    function setUp() public {
        _owner = makeAddr("owner");
        _tokenFactoryAddr = makeAddr("tokenFactory");

        vm.startPrank(_owner);
        _tokenIpCollection = new SpotlightTokenIPCollection(_tokenFactoryAddr);
        _tokenIpCollection.setDefaultTokenURI(defaultTokenURI);
        vm.stopPrank();
        _tokenIpCollectionAddr = address(_tokenIpCollection);
    }

    function testSpotlightTokenCollectionConstructor() public view {
        assertEq(_tokenIpCollection.owner(), _owner);
        assertEq(_tokenIpCollection.tokenFactory(), _tokenFactoryAddr);
        assertEq(_tokenIpCollection.totalSupply(), 0);
        assertEq(_tokenIpCollection.isMintEnabled(), false);
        assertEq(_tokenIpCollection.isTransferEnabled(), false);
        assertEq(_tokenIpCollection.name(), "Spotlight Token IP");
        assertEq(_tokenIpCollection.symbol(), "SPTIP");
    }

    function testNotOwnerSetMintEnabled() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _tokenIpCollection.setMintEnabled(true);
        vm.stopPrank();
    }

    function testSetMintEnabled() public {
        _enableMint();
        assert(_tokenIpCollection.isMintEnabled());
        _disableMint();
        assert(!_tokenIpCollection.isMintEnabled());
    }

    function testNotOwnerSetTransferEnabled() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _tokenIpCollection.setTransferEnabled(true);
        vm.stopPrank();
    }

    function testSetTransferEnabled() public {
        _enableTransfer();
        assert(_tokenIpCollection.isTransferEnabled());
        _disableTransfer();
        assert(!_tokenIpCollection.isTransferEnabled());
    }

    function testNotOwnerSetTokenFactory() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _tokenIpCollection.setTokenFactory(notOwner);
        vm.stopPrank();
    }

    function testSetTokenFactory() public {
        address newTokenFactory = makeAddr("newTokenFactory");
        vm.startPrank(_owner);
        _tokenIpCollection.setTokenFactory(newTokenFactory);
        vm.stopPrank();
        assertEq(_tokenIpCollection.tokenFactory(), newTokenFactory);
    }

    function testNotOwnerSetDefaultTokenURI() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _tokenIpCollection.setDefaultTokenURI(newTokenURI);
        vm.stopPrank();
    }

    function testUserMintBeforeMintEnabled() public {
        address receiver = makeAddr("receiver");
        vm.startPrank(receiver);
        vm.expectRevert("SpotlightTokenCollection: mint is disabled");
        _tokenIpCollection.mint(receiver, 0);
        vm.stopPrank();
    }

    function testUserMint() public {
        address receiver = makeAddr("receiver");
        uint256 totalSupplyBefore = _tokenIpCollection.totalSupply();
        uint256 tokenId = 0;

        _enableMint();
        vm.startPrank(receiver);
        _tokenIpCollection.mint(receiver, tokenId);
        vm.stopPrank();

        assertEq(_tokenIpCollection.totalSupply(), totalSupplyBefore + 1);
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
        assertEq(_tokenIpCollection.tokenURI(tokenId), defaultTokenURI);
    }

    function testTokenFactoryMint() public {
        address receiver = makeAddr("receiver");
        uint256 tokenId = 0;

        uint256 totalSupplyBefore = _tokenIpCollection.totalSupply();
        _mint(_tokenFactoryAddr, receiver, tokenId);

        assertEq(_tokenIpCollection.totalSupply(), totalSupplyBefore + 1);
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
        assertEq(_tokenIpCollection.tokenURI(tokenId), defaultTokenURI);
    }

    function testOwnerMint() public {
        address receiver = makeAddr("receiver");
        uint256 tokenId = 0;

        uint256 totalSupplyBefore = _tokenIpCollection.totalSupply();
        _mint(_owner, receiver, tokenId);

        assertEq(_tokenIpCollection.totalSupply(), totalSupplyBefore + 1);
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
        assertEq(_tokenIpCollection.tokenURI(tokenId), defaultTokenURI);
    }

    function testMintWithExistingTokenId() public {
        address receiver = makeAddr("receiver");
        uint256 tokenId = 0;

        _enableMint();
        _mint(_tokenFactoryAddr, receiver, tokenId);

        vm.startPrank(receiver);
        vm.expectRevert("SpotlightTokenCollection: token already minted");
        _tokenIpCollection.mint(receiver, tokenId);
        vm.stopPrank();
    }

    function testSetDefaultTokenURI() public {
        address receiver = makeAddr("receiver");
        uint256 tokenId = 0;
        _mint(_owner, receiver, tokenId);

        vm.startPrank(_owner);
        _tokenIpCollection.setDefaultTokenURI(newTokenURI);
        vm.stopPrank();

        assertEq(_tokenIpCollection.tokenURI(tokenId), newTokenURI);
    }

    function testNotOwnerSetBaseTokenURI() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _tokenIpCollection.setBaseURI(newTokenURI);
        vm.stopPrank();
    }

    function testSetBaseURI() public {
        address receiver = makeAddr("receiver");
        uint256 tokenId = 0;
        _mint(_owner, receiver, tokenId);

        vm.startPrank(_owner);
        _tokenIpCollection.setBaseURI(newTokenURI);
        vm.stopPrank();

        assertEq(_tokenIpCollection.tokenURI(tokenId), "https://example.com/new-token/0");
    }

    function testUserTransferFromBeforeEnabled() public {
        address sender = makeAddr("sender");
        address receiver = makeAddr("receiver");
        uint256 tokenId = 0;
        _mint(_tokenFactoryAddr, sender, tokenId);

        vm.startPrank(sender);
        vm.expectRevert("SpotlightTokenCollection: transfer is disabled");
        _tokenIpCollection.transferFrom(sender, receiver, tokenId);
        vm.stopPrank();
    }

    function testUserSafeTransferFromBeforeEnabled() public {
        address sender = makeAddr("sender");
        address receiver = makeAddr("receiver");
        uint256 tokenId = 0;
        _mint(_tokenFactoryAddr, sender, tokenId);

        vm.startPrank(sender);
        vm.expectRevert("SpotlightTokenCollection: transfer is disabled");
        _tokenIpCollection.safeTransferFrom(sender, receiver, tokenId);
        vm.stopPrank();
    }

    function testUserSafeTransferFromWithDataBeforeEnabled() public {
        address sender = makeAddr("sender");
        address receiver = makeAddr("receiver");
        uint256 tokenId = 0;
        _mint(_tokenFactoryAddr, sender, tokenId);

        vm.startPrank(sender);
        vm.expectRevert("SpotlightTokenCollection: transfer is disabled");
        _tokenIpCollection.safeTransferFrom(sender, receiver, tokenId, "0x");
        vm.stopPrank();
    }

    function testUserTransferFrom() public {
        address sender = makeAddr("sender");
        address receiver = makeAddr("receiver");
        uint256 tokenId = 0;

        _mint(_tokenFactoryAddr, sender, tokenId);
        _enableTransfer();

        vm.startPrank(sender);
        _tokenIpCollection.transferFrom(sender, receiver, tokenId);
        vm.stopPrank();
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
    }

    function testUserSafeTransferFrom() public {
        address sender = makeAddr("sender");
        address receiver = makeAddr("receiver");
        uint256 tokenId = 0;
        _mint(_tokenFactoryAddr, sender, tokenId);
        _enableTransfer();

        vm.startPrank(sender);
        _tokenIpCollection.safeTransferFrom(sender, receiver, tokenId);
        vm.stopPrank();
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
    }

    function testUserSafeTransferFromWithData() public {
        address sender = makeAddr("sender");
        address receiver = makeAddr("receiver");
        uint256 tokenId = 0;
        _mint(_tokenFactoryAddr, sender, tokenId);
        _enableTransfer();

        vm.startPrank(sender);
        _tokenIpCollection.safeTransferFrom(sender, receiver, tokenId, "0x");
        vm.stopPrank();
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
    }

    function testTokenFactoryTransferFrom() public {
        address receiver = makeAddr("receiver");
        uint256 tokenId = 0;
        _mint(_tokenFactoryAddr, _tokenFactoryAddr, tokenId);

        vm.startPrank(_tokenFactoryAddr);
        _tokenIpCollection.transferFrom(_tokenFactoryAddr, receiver, tokenId);
        vm.stopPrank();
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
    }

    function testTokenFactorySafeTransferFrom() public {
        address receiver = makeAddr("receiver");
        uint256 tokenId = 0;
        _mint(_tokenFactoryAddr, _tokenFactoryAddr, tokenId);

        vm.startPrank(_tokenFactoryAddr);
        _tokenIpCollection.safeTransferFrom(_tokenFactoryAddr, receiver, tokenId);
        vm.stopPrank();
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
    }

    function testTokenFactorySafeTransferFromWithData() public {
        address receiver = makeAddr("receiver");
        uint256 tokenId = 0;
        _mint(_tokenFactoryAddr, _tokenFactoryAddr, tokenId);

        vm.startPrank(_tokenFactoryAddr);
        _tokenIpCollection.safeTransferFrom(_tokenFactoryAddr, receiver, tokenId, "0x");
        vm.stopPrank();
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
    }

    function testOwnerTransferFrom() public {
        address receiver = makeAddr("receiver");
        uint256 tokenId = 0;
        _mint(_owner, _owner, tokenId);

        vm.startPrank(_owner);
        _tokenIpCollection.transferFrom(_owner, receiver, tokenId);
        vm.stopPrank();
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
    }

    function testOwnerSafeTransferFrom() public {
        address receiver = makeAddr("receiver");
        uint256 tokenId = 0;
        _mint(_owner, _owner, tokenId);

        vm.startPrank(_owner);
        _tokenIpCollection.safeTransferFrom(_owner, receiver, tokenId);
        vm.stopPrank();
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
    }

    function testOwnerSafeTransferFromWithData() public {
        address receiver = makeAddr("receiver");
        uint256 tokenId = 0;
        _mint(_owner, _owner, tokenId);

        vm.startPrank(_owner);
        _tokenIpCollection.safeTransferFrom(_owner, receiver, tokenId, "0x");
        vm.stopPrank();
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
    }

    // @dev Private functions
    function _enableTransfer() private {
        vm.startPrank(_owner);
        _tokenIpCollection.setTransferEnabled(true);
        vm.stopPrank();
    }

    function _disableTransfer() private {
        vm.startPrank(_owner);
        _tokenIpCollection.setTransferEnabled(false);
        vm.stopPrank();
    }

    function _enableMint() private {
        vm.startPrank(_owner);
        _tokenIpCollection.setMintEnabled(true);
        vm.stopPrank();
    }

    function _disableMint() private {
        vm.startPrank(_owner);
        _tokenIpCollection.setMintEnabled(false);
        vm.stopPrank();
    }

    function _mint(address minter, address receiver, uint256 tokenId) private {
        vm.startPrank(minter);
        _tokenIpCollection.mint(receiver, tokenId);
        vm.stopPrank();
    }
}
