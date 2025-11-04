// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ISimpleDEXPair {
// events
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

// view functions
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function balanceOf(address owner) external view returns (uint);
    function totalSupply() external view returns (uint);

// state changing functions    
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amountA, uint amountB);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

}
