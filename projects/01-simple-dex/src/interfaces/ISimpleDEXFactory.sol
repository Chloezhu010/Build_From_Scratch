// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ISimpleDEXFactory {
// event
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
// getter
    // get all pairs count
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairsLength() external view returns (uint);
// setter
    function createPair(address tokenA, address tokenB) external returns (address pair);
}