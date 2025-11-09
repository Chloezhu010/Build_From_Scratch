// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ISimpleDEXRouter {
//==================================
// Liquidity functions
//==================================
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

//==================================
// Swap functions
//==================================
    // give exact input, return variable output
    function swapExactTokensforTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    // give exact output, return variable input
    function swapTokensforExactTokens(
        uint amountOut,
        uint amountInMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

//==================================
// Helper functions
//==================================
    // get output amount for exact input
    // function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    // // get required input amount for exact output
    // function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}