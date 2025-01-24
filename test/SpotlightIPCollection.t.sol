// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;
import "../lib/forge-std/src/Test.sol";
import {SpotlightIPCollection} from "../src/spotlight-ip-collection/SpotlightIPCollection.sol";

abstract contract OwnableError {
    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);
}

contract SpotlightIPCollectionTest is Test {
    address private _ownerAddr;

    SpotlightIPCollection private _spotlightIPCollection;
    address private _spotlightIPCollectionAddr;

    string private originalTokenURI = "https://example.com/original-token/";
    string private newTokenURI = "https://example.com/new-token/";

    function setUp() public {
        _ownerAddr = makeAddr("owner");
        vm.startPrank(_ownerAddr);
        _spotlightIPCollection = new SpotlightIPCollection();
        _spotlightIPCollectionAddr = address(_spotlightIPCollection);
        _spotlightIPCollection.setDefaultTokenURI(originalTokenURI);
        vm.stopPrank();
    }

    function test_constructor() public view {
        assertEq(_spotlightIPCollection.owner(), _ownerAddr);
        assertEq(_spotlightIPCollection.totalSupply(), 0);
        assertEq(_spotlightIPCollection.isMintEnabled(), false);
        assertEq(_spotlightIPCollection.isTransferEnabled(), false);
        assertEq(_spotlightIPCollection.name(), "Spotlight IP");
        assertEq(_spotlightIPCollection.symbol(), "SPIP");
    }

    function test_notOwnerSetMintEnabled() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _spotlightIPCollection.setMintEnabled(true);
        vm.stopPrank();
    }

    function test_setMintEnabled() public {
        _enableMint();
        assert(_spotlightIPCollection.isMintEnabled());
        _disableMin();
        assert(!_spotlightIPCollection.isMintEnabled());
    }

    function test_mintBeforeEnabled() public {
        address receiver = makeAddr("receiver");
        vm.startPrank(receiver);
        vm.expectRevert("SpotlightIPCollection: mint is disabled");
        _spotlightIPCollection.mint();
        vm.stopPrank();
    }

    function test_notOwnerMintTo() public {
        address notOwner = makeAddr("notOwner");
        address receiver = makeAddr("receiver");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _mintTo(receiver);
        vm.stopPrank();
    }

    function test_mintToBeforeEnabled() public {
        address receiver = makeAddr("receiver");
        vm.startPrank(_ownerAddr);
        vm.expectRevert("SpotlightIPCollection: mint is disabled");
        _spotlightIPCollection.mint(receiver);
        vm.stopPrank();
    }

    function test_mint() public {
        uint originalTotalSupply = _spotlightIPCollection.totalSupply();
        address receiver = makeAddr("receiver");

        uint256 tokenId = _mint(receiver);

        assertEq(_spotlightIPCollection.totalSupply(), originalTotalSupply + 1);
        assertEq(_spotlightIPCollection.ownerOf(tokenId), receiver);
        assertEq(_spotlightIPCollection.tokenURI(tokenId), originalTokenURI);
    }

    function test_mintTo() public {
        uint originalTotalSupply = _spotlightIPCollection.totalSupply();
        address receiver = makeAddr("receiver");

        uint256 tokenId = _mintTo(receiver);

        assertEq(_spotlightIPCollection.totalSupply(), originalTotalSupply + 1);
        assertEq(_spotlightIPCollection.ownerOf(tokenId), receiver);
        assertEq(_spotlightIPCollection.tokenURI(tokenId), originalTokenURI);
    }

    function test_notOwnerSetTransferEnabled() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _spotlightIPCollection.setTransferEnabled(true);
        vm.stopPrank();
    }

    function test_setTransferEnabled() public {
        _enableTransfer();
        assert(_spotlightIPCollection.isTransferEnabled());
        _disableTransfer();
        assert(!_spotlightIPCollection.isTransferEnabled());
    }

    function test_notOwnerSetDefaultTokenURI() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _spotlightIPCollection.setDefaultTokenURI(newTokenURI);
        vm.stopPrank();
    }

    function test_setDefaultTokenURI() public {
        address receiver = makeAddr("receiver");
        uint256 tokenId = _mint(receiver);

        vm.startPrank(_ownerAddr);
        _spotlightIPCollection.setDefaultTokenURI(newTokenURI);
        vm.stopPrank();

        assertEq(_spotlightIPCollection.tokenURI(tokenId), newTokenURI);
    }

    function test_notOwnerSetBaseURI() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert();
        _spotlightIPCollection.setBaseURI(newTokenURI);
        vm.stopPrank();
    }

    function test_setBaseURI() public {
        address receiver = makeAddr("receiver");
        _mint(receiver);

        vm.startPrank(_ownerAddr);
        _spotlightIPCollection.setBaseURI(newTokenURI);
        vm.stopPrank();

        assertEq(_spotlightIPCollection.tokenURI(0), "https://example.com/new-token/0");
    }

    function test_transferFromBeforeEnabled() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");

        uint256 tokenId = _mint(user1);
        vm.startPrank(user1);
        vm.expectRevert("SpotlightIPCollection: transfer is disabled");
        _spotlightIPCollection.transferFrom(user1, user2, tokenId);
        vm.stopPrank();
    }

    function test_safeTransferFromBeforeEnabled() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");

        uint256 tokenId = _mint(user1);
        vm.startPrank(user1);
        vm.expectRevert("SpotlightIPCollection: transfer is disabled");
        _spotlightIPCollection.safeTransferFrom(user1, user2, tokenId);
        vm.stopPrank();
    }

    function test_safeTransferFromWithDataBeforeEnabled() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");

        uint256 tokenId = _mint(user1);
        vm.startPrank(user1);
        vm.expectRevert("SpotlightIPCollection: transfer is disabled");
        _spotlightIPCollection.safeTransferFrom(user1, user2, tokenId, "");
        vm.stopPrank();
    }

    function test_transferFrom() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");

        uint256 tokenId = _mint(user1);
        _enableTransfer();
        vm.startPrank(user1);
        _spotlightIPCollection.transferFrom(user1, user2, tokenId);
        vm.stopPrank();

        assertEq(_spotlightIPCollection.ownerOf(tokenId), user2);
    }

    function test_safeTransferFrom() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");

        uint256 tokenId = _mint(user1);
        _enableTransfer();
        vm.startPrank(user1);
        _spotlightIPCollection.safeTransferFrom(user1, user2, tokenId);
        vm.stopPrank();

        assertEq(_spotlightIPCollection.ownerOf(tokenId), user2);
    }

    function test_safeTransferFromWithData() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");

        uint256 tokenId = _mint(user1);
        _enableTransfer();
        vm.startPrank(user1);
        _spotlightIPCollection.safeTransferFrom(user1, user2, tokenId, "");
        vm.stopPrank();

        assertEq(_spotlightIPCollection.ownerOf(tokenId), user2);
    }

    // MARK: - Private functions

    function _enableTransfer() private {
        vm.startPrank(_ownerAddr);
        _spotlightIPCollection.setTransferEnabled(true);
        vm.stopPrank();
    }

    function _disableTransfer() private {
        vm.startPrank(_ownerAddr);
        _spotlightIPCollection.setTransferEnabled(false);
        vm.stopPrank();
    }

    function _enableMint() private {
        vm.startPrank(_ownerAddr);
        _spotlightIPCollection.setMintEnabled(true);
        vm.stopPrank();
    }

    function _disableMin() private {
        vm.startPrank(_ownerAddr);
        _spotlightIPCollection.setMintEnabled(false);
        vm.stopPrank();
    }

    function _mint(address _receiver) private returns (uint256) {
        _enableMint();
        vm.startPrank(_receiver);
        uint256 tokenId = _spotlightIPCollection.mint();
        vm.stopPrank();
        return tokenId;
    }

    function _mintTo(address _receiver) private returns (uint256) {
        _enableMint();
        vm.startPrank(_ownerAddr);
        uint256 tokenId = _spotlightIPCollection.mint(_receiver);
        vm.stopPrank();
        return tokenId;
    }
}
