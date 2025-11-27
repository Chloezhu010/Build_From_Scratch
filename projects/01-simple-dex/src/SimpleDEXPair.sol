// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/ISimpleDEXPair.sol";
import "./interfaces/ISimpleDEXERC20.sol";
import "./SimpleDEXERC20.sol";
import "./lib/Math.sol";

contract SimpleDEXPair is ISimpleDEXPair, SimpleDEXERC20 {
    // pool tokens
    address public factory;
    address public token0;
    address public token1;

    // reserves (access via getReserves)
    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    // min liquidity
    uint public constant MIN_LIQUIDITY = 10**3;
    
    constructor() {
        factory = msg.sender;
    }

    // prevent reentrancy attacks
    bool private locked;
    modifier lock() {
        require(locked == false, "SimpleDEXPair: LOCKED");
        locked = true;
        _;
        locked = false;
    }

    // init with token address (call by the factory)
    function initialize(address _token0, address _token1) external {
        // only factory can call this function
        require(factory == msg.sender, "SimpleDEXPair: FORBIDDEN");
        token0 = _token0;
        token1 = _token1;
    }

    // return tokens reserves and last block timestamp
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast){
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // update reserves helper function
    function _update(uint balance0, uint balance1) internal {
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = uint32(block.timestamp);
    }

// state changing functions
    // mint LP tokens
    function mint(address to) external lock returns (uint liquidity){
    // get current state: reserves, balance of tokens
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint balance0 = ISimpleDEXERC20(token0).balanceOf(address(this));
        uint balance1 = ISimpleDEXERC20(token1).balanceOf(address(this));
    // get total LP token supply
        uint _totalSupply = ISimpleDEXERC20(address(this)).totalSupply();
    // calculate amounts of tokens deposited
        // deposited amount = balance - reserve
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;
    // calculate LP token to mint
        if (_totalSupply == 0){
            // LP amount = sqrt(amount0 * amount1) - min liquidity
            liquidity = Math.sqrt(amount0 * amount1);
            require(liquidity > MIN_LIQUIDITY, "SimpleDEXPair: INSUFFICIENT_LIQUIDITY_MINTED"); // prevent underflow
            liquidity -= MIN_LIQUIDITY;
            // burn the min liquidity
            _mint(address(0), MIN_LIQUIDITY);
        }
        else {
            // LP amount = min(amount0 * totalSupply / reserve0, amount1 * totalSupply / reserve1)
            liquidity = Math.min(
                amount0 * _totalSupply / _reserve0,
                amount1 * _totalSupply / _reserve1
            );
        }
    // validate
        require(liquidity > 0, "SimpleDEXPair: INSUFFICIENT_LIQUIDITY_MINTED");
    // mint LP tokens to the caller
        _mint(to, liquidity);
    // update reserves
        _update(balance0, balance1);
    // emit event
        emit Mint(msg.sender, amount0, amount1);
    }

    // burn LP tokens
    function burn(address to) external lock returns (uint amount0, uint amount1){
    // get current state: reserves, balance of tokens
        // (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint balance0 = ISimpleDEXERC20(token0).balanceOf(address(this));
        uint balance1 = ISimpleDEXERC20(token1).balanceOf(address(this));
    // get total LP token supply
        uint _totalSupply = ISimpleDEXERC20(address(this)).totalSupply();
    // get LP tokens sent from the caller
        uint liquidity = balanceOf[address(this)];
    // calculate amounts of tokens to send to the caller
        // amount = liquidity * balance / totalSupply
        require(_totalSupply > 0, "SimpleDEXPair: INSUFFICIENT_LIQUIDITY_MINTED");
        uint _amount0 = liquidity * balance0 / _totalSupply;
        uint _amount1 = liquidity * balance1 / _totalSupply;
    // validate
        require(_amount0 > 0 && _amount1 > 0, "SimpleDEXPair: INSUFFICIENT_LIQUIDITY_BURNED");
    // burn LP tokens
        _burn(address(this), liquidity);
    // send tokens to the caller
        ISimpleDEXERC20(token0).transfer(to, _amount0);
        ISimpleDEXERC20(token1).transfer(to, _amount1);
    // update balances of tokens
        balance0 = ISimpleDEXERC20(token0).balanceOf(address(this));
        balance1 = ISimpleDEXERC20(token1).balanceOf(address(this));
    // update reserves
        _update(balance0, balance1);
    // emit event
        emit Burn(msg.sender, _amount0, _amount1, to);
    // return the amounts of tokens burned
        return (_amount0, _amount1);
    }

    function swap(uint amount0Out, uint amount1Out, address to) external lock{
    // input validation
        // amount out must be positive
        require(amount0Out > 0 || amount1Out > 0, "SimpleDEXPair: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 r0, uint112 r1,) = getReserves();
        // amount out must be less than reserves
        require(amount0Out < r0 && amount1Out < r1, "SimpleDEXPair: INSUFFICIENT_RESERVE");

        uint balance0;
        uint balance1;
    { // avoid stack too deep
        // cached token addresses
        address _token0 = token0;
        address _token1 = token1;
        // recipient address is not the token address
        require(to != _token0 && to != _token1, "SimpleDEXPair: INVALID_TO");
    // optimistic transfer
        if (amount0Out > 0) ISimpleDEXERC20(_token0).transfer(to, amount0Out);
        if (amount1Out > 0) ISimpleDEXERC20(_token1).transfer(to, amount1Out);
    // execute flash loan callback (TBU)

    // check token balance
        balance0 = ISimpleDEXERC20(_token0).balanceOf(address(this));
        balance1 = ISimpleDEXERC20(_token1).balanceOf(address(this));
    }
        uint amount0In = balance0 > r0 - amount0Out ? balance0 - (r0 - amount0Out) : 0;
        uint amount1In = balance1 > r1 - amount1Out ? balance1 - (r1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "SimpleDEXPair: INSUFFICIENT_INPUT_AMOUNT");

    // validate constant product formula
    { // avoid stack too deep
        uint balance0Adj = balance0 * 1000 - amount0In * 3;
        uint balance1Adj = balance1 * 1000 - amount1In * 3;
        require(balance0Adj * balance1Adj >= uint(r0) * uint(r1), "SimpleDEXPair: K_VALUE_VIOLATION");
    }
    // update reserves
        _update(balance0, balance1);
    // emit event
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }
    
}