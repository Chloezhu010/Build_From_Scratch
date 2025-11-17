// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/ISimpleDEXRouter.sol";
import "./interfaces/ISimpleDEXFactory.sol";
import "./interfaces/ISimpleDEXPair.sol";
import "./interfaces/ISimpleDEXERC20.sol";
import "./SimpleDEXPair.sol";

contract SimpleDEXRouter is ISimpleDEXRouter {
//==================================
// State variables & Setups
//==================================
    address public immutable factory;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "SimpleDEXRouter: EXPIRED");
        _;
    }

    constructor(address _factory) {
        factory = _factory;
    }

//==================================
// Liquidity functions
//==================================
    
    function pairFor(address tokenA, address tokenB) public view returns (address pair) {
        // sort token
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB): (tokenB, tokenA);
        // create salt (must match factory's salt)
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // get bytecode hash of SimpleDEXPair
        bytes32 bytecodeHash = keccak256(abi.encodePacked(type(SimpleDEXPair).creationCode));
        // calculate deterministic address using CREATE2 formula
        pair = address(uint160(uint256((keccak256(abi.encodePacked(
            hex'ff',
            address(factory),
            salt,
            bytecodeHash
        ))))));
    }

    // helper function: calculate the optimal amountA, amountB to deposit
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin) 
    internal returns (uint amountA, uint amountB) {
        // create the pair if doesn't exist
        if (ISimpleDEXFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            ISimpleDEXFactory(factory).createPair(tokenA, tokenB);
        }
        // get pair
        address pair = ISimpleDEXFactory(factory).getPair(tokenA, tokenB);
        // get reserves
        (uint reA, uint reB,) = ISimpleDEXPair(pair).getReserves();
        // if reserves = 0
        if (reA == 0 && reB == 0){
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else { // if already have reserves
            uint amountBOptimal = quote(amountADesired, reA, reB);
            if (amountBOptimal <= amountBDesired){
                require(amountBOptimal >= amountBMin, "SimpleDEXRouter: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = quote(amountBDesired, reB, reA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "SimpleDEXRouter: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint amountA, uint amountB, uint liquidity){
        // calculate the optimal amount of token A-B to be deposited
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        // lookup the pair address for tokenA-B
        address pair = pairFor(tokenA, tokenB);
        // transfer the calculated amount to the pair address
        require(ISimpleDEXERC20(tokenA).transferFrom(msg.sender, pair, amountA), "SimpleDEXRouter: TRANSFER_FAILED");
        require(ISimpleDEXERC20(tokenB).transferFrom(msg.sender, pair, amountB), "SimpleDEXRouter: TRANSFER_FAILED");
        // mint LP tokens
        liquidity = ISimpleDEXPair(pair).mint(to);        
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint amountA, uint amountB){
        // look for the pair
        address pair = pairFor(tokenA, tokenB);
        require(pair != address(0), "SimpleDEXRouter: PAIR_DOESNT_EXIST");
        // send LP token to the pair
        require(ISimpleDEXERC20(pair).transferFrom(msg.sender, pair, liquidity), "SimpleDEXRouter: TRANSFER_FAILED");
        // burn LP token
        (uint amount0, uint amount1) = ISimpleDEXPair(pair).burn(to);
        // order the token amounts to match the sorted token order
        (address token0,) = tokenA < tokenB? (tokenA, tokenB): (tokenB, tokenA);
        (amountA, amountB) = token0 == tokenA? (amount0, amount1): (amount1, amount0);
        // check amount is larger than min acceptance amount
        require(amountA >= amountAMin, "SimpleDEXRouter: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "SimpleDEXRouter: INSUFFICIENT_B_AMOUNT");
    }

//==================================
// Swap functions
//==================================
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal {
        // loop thorugh each pair in the path
        for (uint i; i < path.length - 1; i++){
            // extract current pair
            (address input, address output) = (path[i], path[i + 1]);
            // sort tokens and return token0 address
            (address token0,) = input < output? (input, output): (output, input);
            // get pre-calculated amountOut for this swap
            uint amountOut = amounts[i + 1];
            // check if amountOut is token0, update the output with amountOut
            (uint amount0Out, uint amount1Out) = input == token0? (uint(0), amountOut): (amountOut, uint(0));
            // determine the output recipient
            address to = i < path.length - 2? pairFor(output, path[i + 2]): _to;
            // call pair contract's swap function
            address pair = pairFor(input, output);
            ISimpleDEXPair(pair).swap(amount0Out, amount1Out, to);
        }    
    }

    // give exact input, return variable output
    function swapExactTokensforTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts){
        // cal the amountOut for the multi-hop swap
        amounts = getAmountsOut(amountIn, path);
        // check the final amountOut vs the amountOutMin
        require(amounts[amounts.length - 1] >= amountOutMin, "SimpleDEXRouter: INSUFFICIENT_AMOUNT_OUT");
        // init the first swap
        address firstPair = pairFor(path[0], path[1]);
        require(ISimpleDEXERC20(path[0]).transferFrom(
            msg.sender, // from the user
            firstPair, // to the 1st pair contract address
            amounts[0]) // the input amount
            ,"SimpleDEXRouter: TRANSFER_FAILED");
        // handle the rest of the swap chain
        _swap(amounts, path, to);
    }

    // give exact output, return variable input
    function swapTokensforExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts){
        amounts = getAmountsIn(amountOut, path);
        require(amounts[0] <= amountInMax, "SimpleDEXRouter: EXCESSIVE_INPUT_AMOUNT");
        address firstPair = pairFor(path[0], path[1]);
        require(ISimpleDEXERC20(path[0]).transferFrom(
            msg.sender, // from the user
            firstPair, // to the 1st pair contract address
            amounts[0]) // the input amount
            ,"SimpleDEXRouter: TRANSFER_FAILED");
        _swap(amounts, path, to);
    }

//==================================
// Helper functions
//==================================

    // give certain amount of an assert and pool reserve, returns the equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, "SimpleDEXPair: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "SimpleDEXPair: INSUFFICIENT_LIQUIDITY");
        amountB = amountA * reserveB / reserveA;
    }

    // get output amount for exact input
    // amountOut = (reserveOut x amountIn x 997) / (reserveIn x 1000 + amountIn x 997)
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
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
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure returns (uint amountIn) {
        // input validation
        require(amountOut > 0, "SimpleDEXRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SimpleDEXRouter: INSUFFICIENT_LIQUIDITY");
        // calculate amountIn
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator;
    }

    // perform chained getAmountOut on any number of pairs
    function getAmountsOut(uint amountIn, address[] calldata path) public view returns (uint[] memory amounts){
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
    function getAmountsIn(uint amountOut, address[] calldata path) public view returns (uint[] memory amounts){
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