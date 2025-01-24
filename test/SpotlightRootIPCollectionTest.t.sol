// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import {SpotlightRootIPCollection} from "../src/spotlight-root-ip-collection/SpotlightRootIPCollection.sol";

abstract contract OwnableError {
    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);
}

contract SpotlightRootIPCollectionTest is Test {
    address private _ownerAddr;

    SpotlightRootIPCollection private _spotlightRootIPCollection;
    address private _spotlightRootIPCollectionAddr;

    string private newTokenURI = "https://example.com/new-token/";

    function setUp() public {
        _ownerAddr = makeAddr("owner");
        vm.startPrank(_ownerAddr);
        _spotlightRootIPCollection = new SpotlightRootIPCollection();
        _spotlightRootIPCollectionAddr = address(_spotlightRootIPCollection);
        vm.stopPrank();
    }

    function test_constructor() public view {
        assertEq(_spotlightRootIPCollection.owner(), _ownerAddr);
        assertEq(_spotlightRootIPCollection.totalSupply(), 0);
        assertEq(_spotlightRootIPCollection.isTransferEnabled(), false);
        assertEq(_spotlightRootIPCollection.name(), "Spotlight Root IP");
        assertEq(_spotlightRootIPCollection.symbol(), "SPRIP");
    }

    function test_notOownerMint() public {
        address receiver = makeAddr("receiver");

        vm.startPrank(receiver);
        vm.expectRevert();
        _spotlightRootIPCollection.mint();
        vm.stopPrank();
    }

    function test_mint() public {
        vm.startPrank(_ownerAddr);
        uint256 tokenId = _spotlightRootIPCollection.mint();
        vm.stopPrank();

        assertEq(_spotlightRootIPCollection.totalSupply(), 1);
        assertEq(_spotlightRootIPCollection.ownerOf(tokenId), _ownerAddr);
        assertEq(
            _spotlightRootIPCollection.tokenURI(tokenId),
            "ipfs://bafkreidsyc4pkxkk7io56uf5hhnvkx2n6ukua4xjg42dsv5n7y2hbb3h3u"
        );
    }

    function test_notOwnerSetTransferEnabled() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _spotlightRootIPCollection.setTransferEnabled(true);
        vm.stopPrank();
    }

    function test_setTransferEnabled() public {
        vm.startPrank(_ownerAddr);
        _spotlightRootIPCollection.setTransferEnabled(true);
        assert(_spotlightRootIPCollection.isTransferEnabled());
        _spotlightRootIPCollection.setTransferEnabled(false);
        assert(!_spotlightRootIPCollection.isTransferEnabled());
        vm.stopPrank();
    }

    function test_notOwnerSetTokenURI() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _spotlightRootIPCollection.setTokenURI(newTokenURI);
        vm.stopPrank();
    }

    function test_setTokenURI() public {
        vm.startPrank(_ownerAddr);
        uint256 tokenId = _spotlightRootIPCollection.mint();
        _spotlightRootIPCollection.setTokenURI(newTokenURI);
        vm.stopPrank();

        assertEq(_spotlightRootIPCollection.tokenURI(tokenId), newTokenURI);
    }

    function test_transferFromBeforeEnabled() public {
        address receiver = makeAddr("receiver");

        vm.startPrank(_ownerAddr);
        uint256 tokenId = _spotlightRootIPCollection.mint();
        vm.expectRevert("SpotlightRootIPCollection: transfer is disabled");
        _spotlightRootIPCollection.transferFrom(_ownerAddr, receiver, tokenId);
        vm.stopPrank();
    }

    function test_safeTransferFromBeforeEnabled() public {
        address receiver = makeAddr("receiver");

        vm.startPrank(_ownerAddr);
        uint256 tokenId = _spotlightRootIPCollection.mint();
        vm.expectRevert("SpotlightRootIPCollection: transfer is disabled");
        _spotlightRootIPCollection.safeTransferFrom(_ownerAddr, receiver, tokenId);
        vm.stopPrank();
    }

    function test_safeTransferFromWithDataBeforeEnabled() public {
        address receiver = makeAddr("receiver");

        vm.startPrank(_ownerAddr);
        uint256 tokenId = _spotlightRootIPCollection.mint();
        vm.expectRevert("SpotlightRootIPCollection: transfer is disabled");
        _spotlightRootIPCollection.safeTransferFrom(_ownerAddr, receiver, tokenId, "");
        vm.stopPrank();
    }

    function test_transferFrom() public {
        address receiver = makeAddr("receiver");

        vm.startPrank(_ownerAddr);
        uint256 tokenId = _spotlightRootIPCollection.mint();
        _spotlightRootIPCollection.setTransferEnabled(true);
        _spotlightRootIPCollection.transferFrom(_ownerAddr, receiver, tokenId);
        vm.stopPrank();

        assertEq(_spotlightRootIPCollection.ownerOf(tokenId), receiver);
    }

    function test_safeTransferFrom() public {
        address receiver = makeAddr("receiver");

        vm.startPrank(_ownerAddr);
        uint256 tokenId = _spotlightRootIPCollection.mint();
        _spotlightRootIPCollection.setTransferEnabled(true);
        _spotlightRootIPCollection.safeTransferFrom(_ownerAddr, receiver, tokenId);
        vm.stopPrank();

        assertEq(_spotlightRootIPCollection.ownerOf(tokenId), receiver);
    }

    function test_safeTransferFromWithData() public {
        address receiver = makeAddr("receiver");

        vm.startPrank(_ownerAddr);
        uint256 tokenId = _spotlightRootIPCollection.mint();
        _spotlightRootIPCollection.setTransferEnabled(true);
        _spotlightRootIPCollection.safeTransferFrom(_ownerAddr, receiver, tokenId, "");
        vm.stopPrank();

        assertEq(_spotlightRootIPCollection.ownerOf(tokenId), receiver);
    }
}
