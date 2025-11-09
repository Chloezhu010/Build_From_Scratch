// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/ISimpleDEXRouter.sol";
import "./interfaces/ISimpleDEXFactory.sol";
import "./interfaces/ISimpleDEXPair.sol";

contract SimpleDEXRouter is ISimpleDEXRouter {
//==================================
// State variables & Setups
//==================================
    address public immutable factory;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "SimpleDEXRouter: EXPIRED");
        _;
    }

    constructor(address _factory) public {
        factory = _factory;
    }

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
    ) external returns (uint amountA, uint amountB, uint liquidity){
        // calculate the optimal amount of token A-B to be deposited
        // (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        // lookup the pair address for tokenA-B
        

        // transfer the calculated amount to the pair address

        // mint LP tokens
    }

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
    // amountOut = (reserveOut x amountIn x 997) / (reserveIn x 1000 + amountIn x 997)
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        // input validation
        require(amountIn > 0, "SimpleDEXRouter: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SimpleDEXRouter: INSUFFICIENT_LIQUIDITY");
        // calculate amountOut
        uint numerator = reserveOut * amountIn * 997;
        uint denominator = reserveIn * 1000 + amountIn * 997;
        amountOut = numerator / denominator;
    }

    // get required input amount for exact output
    // amountIn = (reserveIn x amountOut x 1000) / ((reserveOut - amountOut) x 997)
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        // input validation
        require(amountOut > 0, "SimpleDEXRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SimpleDEXRouter: INSUFFICIENT_LIQUIDITY");
        // calculate amountIn
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator;
    }

    // perform chained getAmountOut on any number of pairs
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts){
        // input validation
        require(path.length >= 2, "SimpleDEXRouter: INVALID_PATH");
        // init amounts array
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        // loop through the path to cal getAmountOut
        for (uint i; i < path.length - 1; i++){
            address tokenIn = path[i];
            address tokenOut = path[i + 1];
            // sort token
            (address token0, address token1) = tokenIn < tokenOut ? (tokenIn, tokenOut) : (tokenOut, tokenIn);
            // get pair address from factory
            address pair = ISimpleDEXFactory(factory).getPair(token0, token1);
            require (pair != address(0), "SimpleDEXRouter: PAIR_DOESNT_EXIST");
            // get reserves from the pair
            (uint re0, uint re1,) = ISimpleDEXPair(pair).getReserves();
            // determine which reserve is input vs output
            (uint reIn, uint reOut) = token0 == tokenIn? (re0, re1) : (re1, re0);
            // calculate output amount
            amounts[i + 1] = getAmountOut(amounts[i], reIn, reOut);
        }
    }

    // perform chained getAmountIn on any number of pairs
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts){
        // input validation
        require(path.length >= 2, "SimpleDEXRouter: INVALID_PATH");
        // init amounts array
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut; // backward calculation
        // loop through the path to cal getAmountIn
        for (uint i = path.length - 1; i > 0; i--){
            address tokenOut = path[i];
            address tokenIn = path[i - 1];
            // sort token
            (address token0, address token1) = tokenIn < tokenOut? (tokenIn, tokenOut) : (tokenOut, tokenIn);
            // get pair address from factory
            address pair = ISimpleDEXFactory(factory).getPair(token0, token1);
            require (pair != address(0), "SimpleDEXRouter: PAIR_DOESNT_EXIST");
            // get reserves from pair
            (uint re0, uint re1,) = ISimpleDEXPair(pair).getReserves();
            // determine which reserve is input vs output
            (uint reIn, uint reOut) = token0 == tokenIn? (re0, re1) : (re1, re0);            
            // calculate output amount
            amounts[i - 1] = getAmountIn(amounts[i], reIn, reOut);
        }
    }

}