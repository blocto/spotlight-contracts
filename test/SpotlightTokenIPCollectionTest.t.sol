// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import {SpotlightTokenIPCollection} from "../src/spotlight-token-collection/SpotlightTokenIPCollection.sol";

contract SpotlightTokenIPCollectionTest is Test {
    address private _owner;
    address private _tokenFactoryAddr;

    SpotlightTokenIPCollection private _tokenIpCollection;
    address private _tokenIpCollectionAddr;

    string private originalTokenURI =
        "https://blocto.mypinata.cloud/ipfs/bafkreibqge4t7rsppnarffvrzlfph5rk5ajvupa4oyk4v2h3ieqccty4ye";
    string private newTokenURI = "https://example.com/new-token/";

    function setUp() public {
        _owner = makeAddr("owner");
        _tokenFactoryAddr = makeAddr("tokenFactory");

        _tokenIpCollection = new SpotlightTokenIPCollection(_owner, _tokenFactoryAddr);
        _tokenIpCollectionAddr = address(_tokenIpCollection);
    }

    function testSpotlightTokenCollectionConstructor() public view {
        assertEq(_tokenIpCollection.owner(), _owner);
        assertEq(_tokenIpCollection.tokenFactory(), _tokenFactoryAddr);
        assertEq(_tokenIpCollection.totalSupply(), 0);
        assertEq(_tokenIpCollection.isMintEnabled(), false);
        assertEq(_tokenIpCollection.isTransferEnabled(), false);
        assertEq(_tokenIpCollection.name(), "Spotlight Meme IP");
        assertEq(_tokenIpCollection.symbol(), "Spotlight Meme IP");
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

    function testNotOwnerSetTokenURI() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _tokenIpCollection.setTokenURI(newTokenURI);
        vm.stopPrank();
    }

    function testUserMintBeforeMintEnabled() public {
        address receiver = makeAddr("receiver");
        vm.startPrank(receiver);
        vm.expectRevert("SpotlightTokenCollection: mint is disabled");
        _tokenIpCollection.mint(receiver);
        vm.stopPrank();
    }

    function testUserMint() public {
        address receiver = makeAddr("receiver");
        uint256 totalSupplyBefore = _tokenIpCollection.totalSupply();

        _enableMint();
        vm.startPrank(receiver);
        uint256 tokenId = _tokenIpCollection.mint(receiver);
        vm.stopPrank();

        assertEq(_tokenIpCollection.totalSupply(), totalSupplyBefore + 1);
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
        assertEq(_tokenIpCollection.tokenURI(tokenId), originalTokenURI);
    }

    function testTokenFactoryMint() public {
        address receiver = makeAddr("receiver");
        uint256 totalSupplyBefore = _tokenIpCollection.totalSupply();
        uint256 tokenId = _mint(_tokenFactoryAddr, receiver);

        assertEq(_tokenIpCollection.totalSupply(), totalSupplyBefore + 1);
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
        assertEq(_tokenIpCollection.tokenURI(tokenId), originalTokenURI);
    }

    function testOwnerMint() public {
        address receiver = makeAddr("receiver");
        uint256 totalSupplyBefore = _tokenIpCollection.totalSupply();
        uint256 tokenId = _mint(_owner, receiver);

        assertEq(_tokenIpCollection.totalSupply(), totalSupplyBefore + 1);
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
        assertEq(_tokenIpCollection.tokenURI(tokenId), originalTokenURI);
    }

    function testSetTokenURI() public {
        address receiver = makeAddr("receiver");
        uint256 tokenId = _mint(_owner, receiver);

        vm.startPrank(_owner);
        _tokenIpCollection.setTokenURI(newTokenURI);
        vm.stopPrank();

        assertEq(_tokenIpCollection.tokenURI(tokenId), newTokenURI);
    }

    function testUserTransferFromBeforeEnabled() public {
        address sender = makeAddr("sender");
        address receiver = makeAddr("receiver");
        uint256 tokenId = _mint(_tokenFactoryAddr, sender);

        vm.startPrank(sender);
        vm.expectRevert("SpotlightTokenCollection: transfer is disabled");
        _tokenIpCollection.transferFrom(sender, receiver, tokenId);
        vm.stopPrank();
    }

    function testUserSafeTransferFromBeforeEnabled() public {
        address sender = makeAddr("sender");
        address receiver = makeAddr("receiver");
        uint256 tokenId = _mint(_tokenFactoryAddr, sender);

        vm.startPrank(sender);
        vm.expectRevert("SpotlightTokenCollection: transfer is disabled");
        _tokenIpCollection.safeTransferFrom(sender, receiver, tokenId);
        vm.stopPrank();
    }

    function testUserSafeTransferFromWithDataBeforeEnabled() public {
        address sender = makeAddr("sender");
        address receiver = makeAddr("receiver");
        uint256 tokenId = _mint(_tokenFactoryAddr, sender);

        vm.startPrank(sender);
        vm.expectRevert("SpotlightTokenCollection: transfer is disabled");
        _tokenIpCollection.safeTransferFrom(sender, receiver, tokenId, "0x");
        vm.stopPrank();
    }

    function testUserTransferFrom() public {
        address sender = makeAddr("sender");
        address receiver = makeAddr("receiver");

        uint256 tokenId = _mint(_tokenFactoryAddr, sender);
        _enableTransfer();

        vm.startPrank(sender);
        _tokenIpCollection.transferFrom(sender, receiver, tokenId);
        vm.stopPrank();
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
    }

    function testUserSafeTransferFrom() public {
        address sender = makeAddr("sender");
        address receiver = makeAddr("receiver");

        uint256 tokenId = _mint(_tokenFactoryAddr, sender);
        _enableTransfer();

        vm.startPrank(sender);
        _tokenIpCollection.safeTransferFrom(sender, receiver, tokenId);
        vm.stopPrank();
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
    }

    function testUserSafeTransferFromWithData() public {
        address sender = makeAddr("sender");
        address receiver = makeAddr("receiver");

        uint256 tokenId = _mint(_tokenFactoryAddr, sender);
        _enableTransfer();

        vm.startPrank(sender);
        _tokenIpCollection.safeTransferFrom(sender, receiver, tokenId, "0x");
        vm.stopPrank();
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
    }

    function testTokenFactoryTransferFrom() public {
        address receiver = makeAddr("receiver");
        uint256 tokenId = _mint(_tokenFactoryAddr, _tokenFactoryAddr);

        vm.startPrank(_tokenFactoryAddr);
        _tokenIpCollection.transferFrom(_tokenFactoryAddr, receiver, tokenId);
        vm.stopPrank();
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
    }

    function testTokenFactorySafeTransferFrom() public {
        address receiver = makeAddr("receiver");
        uint256 tokenId = _mint(_tokenFactoryAddr, _tokenFactoryAddr);

        vm.startPrank(_tokenFactoryAddr);
        _tokenIpCollection.safeTransferFrom(_tokenFactoryAddr, receiver, tokenId);
        vm.stopPrank();
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
    }

    function testTokenFactorySafeTransferFromWithData() public {
        address receiver = makeAddr("receiver");
        uint256 tokenId = _mint(_tokenFactoryAddr, _tokenFactoryAddr);

        vm.startPrank(_tokenFactoryAddr);
        _tokenIpCollection.safeTransferFrom(_tokenFactoryAddr, receiver, tokenId, "0x");
        vm.stopPrank();
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
    }

    function testOwnerTransferFrom() public {
        address receiver = makeAddr("receiver");
        uint256 tokenId = _mint(_owner, _owner);

        vm.startPrank(_owner);
        _tokenIpCollection.transferFrom(_owner, receiver, tokenId);
        vm.stopPrank();
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
    }

    function testOwnerSafeTransferFrom() public {
        address receiver = makeAddr("receiver");
        uint256 tokenId = _mint(_owner, _owner);

        vm.startPrank(_owner);
        _tokenIpCollection.safeTransferFrom(_owner, receiver, tokenId);
        vm.stopPrank();
        assertEq(_tokenIpCollection.ownerOf(tokenId), receiver);
    }

    function testOwnerSafeTransferFromWithData() public {
        address receiver = makeAddr("receiver");
        uint256 tokenId = _mint(_owner, _owner);

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

    function _mint(address minter, address receiver) private returns (uint256 tokenId) {
        vm.startPrank(minter);
        tokenId = _tokenIpCollection.mint(receiver);
        vm.stopPrank();
    }
}
