// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import {SpotlightTokenCollection} from "../src/spotlight-token-collection/SpotlightTokenCollection.sol";

contract SpotlightTokenCollectionTest is Test {
    address private _owner;
    address private _tokenFactoryAddr;

    SpotlightTokenCollection private _spotlightTokenCollection;
    address private _spotlightTokenCollectionAddr;

    string private originalTokenURI = "https://example.com/original-token/";
    string private newTokenURI = "https://example.com/new-token/";

    function setUp() public {
        _owner = makeAddr("owner");
        _tokenFactoryAddr = makeAddr("tokenFactory");

        _spotlightTokenCollection = new SpotlightTokenCollection(_owner, _tokenFactoryAddr);
        _spotlightTokenCollectionAddr = address(_spotlightTokenCollection);

        vm.startPrank(_owner);
        _spotlightTokenCollection.setTokenURI(originalTokenURI);
        vm.stopPrank();
    }

    function testSpotlightTokenCollectionConstructor() public view {
        assertEq(_spotlightTokenCollection.owner(), _owner);
        assertEq(_spotlightTokenCollection.tokenFactory(), _tokenFactoryAddr);
        assertEq(_spotlightTokenCollection.totalSupply(), 0);
        assertEq(_spotlightTokenCollection.isMintEnabled(), false);
        assertEq(_spotlightTokenCollection.isTransferEnabled(), false);
        assertEq(_spotlightTokenCollection.name(), "SpotlightTokenCollection");
        assertEq(_spotlightTokenCollection.symbol(), "SpotlightToken");
    }

    function testNotOwnerSetMintEnabled() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _spotlightTokenCollection.setMintEnabled(true);
        vm.stopPrank();
    }

    function testSetMintEnabled() public {
        _enableMint();
        assert(_spotlightTokenCollection.isMintEnabled());
        _disableMint();
        assert(!_spotlightTokenCollection.isMintEnabled());
    }

    function testNotOwnerSetTransferEnabled() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _spotlightTokenCollection.setTransferEnabled(true);
        vm.stopPrank();
    }

    function testSetTransferEnabled() public {
        _enableTransfer();
        assert(_spotlightTokenCollection.isTransferEnabled());
        _disableTransfer();
        assert(!_spotlightTokenCollection.isTransferEnabled());
    }

    function testNotOwnerSetTokenFactory() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _spotlightTokenCollection.setTokenFactory(notOwner);
        vm.stopPrank();
    }

    function testSetTokenFactory() public {
        address newTokenFactory = makeAddr("newTokenFactory");
        vm.startPrank(_owner);
        _spotlightTokenCollection.setTokenFactory(newTokenFactory);
        vm.stopPrank();
        assertEq(_spotlightTokenCollection.tokenFactory(), newTokenFactory);
    }

    function testNotOwnerSetTokenURI() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _spotlightTokenCollection.setTokenURI(newTokenURI);
        vm.stopPrank();
    }

    function testMintBeforeMintEnabled() public {
        address receiver = makeAddr("receiver");
        vm.startPrank(_owner);
        vm.expectRevert("SpotlightTokenCollection: mint is disabled");
        _spotlightTokenCollection.mint(receiver);
        vm.stopPrank();
    }

    function testNotOwnerAndNotFactoryMint() public {
        address receiver = makeAddr("receiver");
        _enableMint();
        vm.startPrank(receiver);
        vm.expectRevert("SpotlightTokenCollection: only owner or token factory can mint");
        _spotlightTokenCollection.mint(receiver);
        vm.stopPrank();
    }

    function testTokenFactoryMint() public {
        address receiver = makeAddr("receiver");
        uint256 totalSupplyBefore = _spotlightTokenCollection.totalSupply();
        uint256 tokenId = _mint(_tokenFactoryAddr, receiver);

        assertEq(_spotlightTokenCollection.totalSupply(), totalSupplyBefore + 1);
        assertEq(_spotlightTokenCollection.ownerOf(tokenId), receiver);
        assertEq(_spotlightTokenCollection.tokenURI(tokenId), originalTokenURI);
    }

    function testOwnerMint() public {
        address receiver = makeAddr("receiver");
        uint256 totalSupplyBefore = _spotlightTokenCollection.totalSupply();
        uint256 tokenId = _mint(_owner, receiver);

        assertEq(_spotlightTokenCollection.totalSupply(), totalSupplyBefore + 1);
        assertEq(_spotlightTokenCollection.ownerOf(tokenId), receiver);
        assertEq(_spotlightTokenCollection.tokenURI(tokenId), originalTokenURI);
    }

    function testSetTokenURI() public {
        address receiver = makeAddr("receiver");
        uint256 tokenId = _mint(_owner, receiver);

        vm.startPrank(_owner);
        _spotlightTokenCollection.setTokenURI(newTokenURI);
        vm.stopPrank();

        assertEq(_spotlightTokenCollection.tokenURI(tokenId), newTokenURI);
    }

    function testTransferFromBeforeEnabled() public {
        address sender = makeAddr("sender");
        address receiver = makeAddr("receiver");
        uint256 tokenId = _mint(_tokenFactoryAddr, sender);

        vm.startPrank(sender);
        vm.expectRevert("SpotlightTokenCollection: transfer is disabled");
        _spotlightTokenCollection.transferFrom(sender, receiver, tokenId);
        vm.stopPrank();
    }

    function testSafeTransferFromBeforeEnabled() public {
        address sender = makeAddr("sender");
        address receiver = makeAddr("receiver");
        uint256 tokenId = _mint(_tokenFactoryAddr, sender);

        vm.startPrank(sender);
        vm.expectRevert("SpotlightTokenCollection: transfer is disabled");
        _spotlightTokenCollection.safeTransferFrom(sender, receiver, tokenId);
        vm.stopPrank();
    }

    function testSafeTransferFromWithDataBeforeEnabled() public {
        address sender = makeAddr("sender");
        address receiver = makeAddr("receiver");
        uint256 tokenId = _mint(_tokenFactoryAddr, sender);

        vm.startPrank(sender);
        vm.expectRevert("SpotlightTokenCollection: transfer is disabled");
        _spotlightTokenCollection.safeTransferFrom(sender, receiver, tokenId, "0x");
        vm.stopPrank();
    }

    function testTransferFrom() public {
        address sender = makeAddr("sender");
        address receiver = makeAddr("receiver");

        uint256 tokenId = _mint(_tokenFactoryAddr, sender);
        _enableTransfer();

        vm.startPrank(sender);
        _spotlightTokenCollection.transferFrom(sender, receiver, tokenId);
        vm.stopPrank();
        assertEq(_spotlightTokenCollection.ownerOf(tokenId), receiver);
    }

    function testSafeTransferFrom() public {
        address sender = makeAddr("sender");
        address receiver = makeAddr("receiver");

        uint256 tokenId = _mint(_tokenFactoryAddr, sender);
        _enableTransfer();

        vm.startPrank(sender);
        _spotlightTokenCollection.safeTransferFrom(sender, receiver, tokenId);
        vm.stopPrank();
        assertEq(_spotlightTokenCollection.ownerOf(tokenId), receiver);
    }

    function testSafeTransferFromWithData() public {
        address sender = makeAddr("sender");
        address receiver = makeAddr("receiver");

        uint256 tokenId = _mint(_tokenFactoryAddr, sender);
        _enableTransfer();

        vm.startPrank(sender);
        _spotlightTokenCollection.safeTransferFrom(sender, receiver, tokenId, "0x");
        vm.stopPrank();
        assertEq(_spotlightTokenCollection.ownerOf(tokenId), receiver);
    }

    // @dev Private functions
    function _enableTransfer() private {
        vm.startPrank(_owner);
        _spotlightTokenCollection.setTransferEnabled(true);
        vm.stopPrank();
    }

    function _disableTransfer() private {
        vm.startPrank(_owner);
        _spotlightTokenCollection.setTransferEnabled(false);
        vm.stopPrank();
    }

    function _enableMint() private {
        vm.startPrank(_owner);
        _spotlightTokenCollection.setMintEnabled(true);
        vm.stopPrank();
    }

    function _disableMint() private {
        vm.startPrank(_owner);
        _spotlightTokenCollection.setMintEnabled(false);
        vm.stopPrank();
    }

    function _mint(address minter, address receiver) private returns (uint256 tokenId) {
        _enableMint();
        vm.startPrank(minter);
        tokenId = _spotlightTokenCollection.mint(receiver);
        vm.stopPrank();
    }
}
