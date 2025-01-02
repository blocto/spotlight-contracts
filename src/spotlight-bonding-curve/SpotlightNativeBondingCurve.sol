// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {FixedPointMathLib} from "../../lib/solady/src/utils/FixedPointMathLib.sol";
import {ISpotlightBondingCurve} from "./ISpotlightBondingCurve.sol";

/**
 * @dev Use IP as base token.
 */
contract SpotlightNativeBondingCurve is ISpotlightBondingCurve {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    uint256 public immutable A;
    uint256 public immutable B;

    constructor(uint256 A_, uint256 B_) {
        A = A_;
        B = B_;
    }

    function getTargetTokenSellQuote(uint256 currentSupply, uint256 targetTokensIn)
        external
        view
        returns (uint256 baseTokensOut)
    {
        if (currentSupply < targetTokensIn) {
            revert("SpotlightUSDCBondingCureve: INSUFFICIENT_SUPPLY");
        }
        uint256 x0 = currentSupply;
        uint256 x1 = x0 - targetTokensIn;

        uint256 exp_b_x0 = uint256((int256(B.mulWad(x0))).expWad());
        uint256 exp_b_x1 = uint256((int256(B.mulWad(x1))).expWad());

        // calculate deltaY = (a/b)*(exp(b*x0) - exp(b*x1))
        baseTokensOut = (exp_b_x0 - exp_b_x1).fullMulDiv(A, B);
    }

    function getBaseTokenBuyQuote(uint256 currentSupply, uint256 basedTokensIn)
        external
        view
        returns (uint256 targetTokensOut)
    {
        uint256 x0 = currentSupply;
        uint256 deltaY = basedTokensIn;

        // calculate exp(b*x0)
        uint256 exp_b_x0 = uint256((int256(B.mulWad(x0))).expWad());

        // calculate exp(b*x0) + (dy*b/a)
        uint256 exp_b_x1 = exp_b_x0 + deltaY.fullMulDiv(B, A);

        targetTokensOut = uint256(int256(exp_b_x1).lnWad()).divWad(B) - x0;
    }

    function getTargetTokenBuyQuote(uint256 currentSupply, uint256 targetTokensOut)
        external
        view
        returns (uint256 basedTokensIn)
    {
        uint256 x0 = currentSupply;
        uint256 x1 = targetTokensOut + currentSupply;

        uint256 exp_b_x0 = uint256((int256(B.mulWad(x0))).expWad());
        uint256 exp_b_x1 = uint256((int256(B.mulWad(x1))).expWad());

        uint256 deltaY = (exp_b_x1 - exp_b_x0).fullMulDiv(A, B);

        // adjust for 12 decimal places difference between deltaY and basedTokensIn
        basedTokensIn = deltaY;
    }
}
