// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import {SpotlightNativeBondingCurve} from "../src/spotlight-bonding-curve/SpotlightNativeBondingCurve.sol";
import {ISpotlightBondingCurve} from "../src/spotlight-bonding-curve/ISpotlightBondingCurve.sol";

contract SpotlightBondingCurveTest is Test {
    ISpotlightBondingCurve _bondingCurve;

    function setUp() public {
        _bondingCurve = new SpotlightNativeBondingCurve(1060848709, 4379701787);
    }

    function testGetBaseTokenBuyQuote_0() public view {
        uint256 currentSupply = 0;
        uint256 baseTokensIn = 0.1 ether; // 0.1 ETH

        uint256 targetTokensOut = _bondingCurve.getBaseTokenBuyQuote(currentSupply, baseTokensIn);

        assertEq(targetTokensOut, 78911339155047068504894988);
    }

    function testGetBaseTokenBuyQuote_1() public view {
        uint256 currentSupply = 93243534057221441062232;
        uint256 baseTokensIn = 500 ether; // 500 ETH

        uint256 targetTokensOut = _bondingCurve.getBaseTokenBuyQuote(currentSupply, baseTokensIn);

        assertEq(targetTokensOut, 1742720392915956197246523859);
    }

    function testGetTargetTokenBuyQuote_0() public view {
        uint256 currentSupply = 0;
        uint256 targetTokensOut = 100_000_000e18; // 0.1B

        uint256 baseTokensIn = _bondingCurve.getTargetTokenBuyQuote(currentSupply, targetTokensOut);
        assertEq(baseTokensIn, 133113774054389860);
    }

    function testGetTargetTokenBuyQuote_1() public view {
        uint256 currentSupply = 500_000_000e18; // 0.5B
        uint256 targetTokensOut = 3_000e18;

        uint256 baseTokensIn = _bondingCurve.getTargetTokenBuyQuote(currentSupply, targetTokensOut);
        assertEq(baseTokensIn, 28432674896780);
    }

    function testGetTargetTokenSellQuote_0() public view {
        uint256 currentSupply = 500_000_000e18; // 0.5B
        uint256 targetTokensIn = 80_000e18; // 80k

        uint256 baseTokensOut = _bondingCurve.getTargetTokenSellQuote(currentSupply, targetTokensIn);
        assertEq(baseTokensOut, 758066870831184);
    }

    function testGetTargetTokenSellQuote_1() public {
        uint256 currentSupply = 10_000; // 0.5B
        uint256 targetTokensIn = 20_000; // 80k

        vm.expectRevert("SpotlightNativeBondingCurve: INSUFFICIENT_SUPPLY");
        _bondingCurve.getTargetTokenSellQuote(currentSupply, targetTokensIn);
    }

    function testGetTargetTokenSellQuote_2() public view {
        uint256 currentSupply = 800_000_000e18; // 0.8B
        uint256 targetTokensIn = 95_000e18; // 95k

        uint256 baseTokensOut = _bondingCurve.getTargetTokenSellQuote(currentSupply, targetTokensIn);
        assertEq(baseTokensOut, 3349276224895252);
    }
}
