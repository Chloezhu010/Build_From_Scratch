// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }       

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function sqrt(uint256 x) internal pure returns (uint256 res) {
        if (x > 3){
            res = x;
            uint256 y = x / 2 + 1;
            while (y < res){
                res = y;
                y = (x / y + y) / 2;
            }
        } else if (x != 0){
            res = 1;
        }
        return res;
    }

    /* given amountA, reserveA, reserveB, calculate amountB
        - amountB = amountA * reserveB / reserveA 
    */
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require (reserveA > 0 && reserveB > 0, "Math: INSUFFICIENT_LIQUIDITY");
        require (amountA > 0, "Math: INSUFFICIENT_AMOUNT");
        amountB = amountA * reserveB / reserveA;
        return amountB;
    }
}