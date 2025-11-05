//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/ISimpleDEXERC20.sol";

contract SimpleDEXERC20 is ISimpleDEXERC20 {
    string public name = "SimpleDEX LP";
    string public symbol = "SLP";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(){}

    function _mint(address to, uint value) internal {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function _transfer(address from, address to, uint value) internal {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function _approve(address owner, address spender, uint value) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function approve(address spender, uint value) external returns (bool){
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool){
        require(balanceOf[msg.sender] >= value, "INSUFFICIENT_BALANCE");
        require(to != address(0), "INVALID_RECIPIENT");
        
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool){
        require(balanceOf[from] >= value, "INSUFFICIENT_BALANCE");
        require(allowance[from][msg.sender] >= value, "INSUFFICIENT_ALLOWANCE");
        require(to != address(0), "INVALID_RECIPIENT");
        require(value > 0, "INVALID_AMOUNT");
    
        _approve(from, msg.sender, allowance[from][msg.sender] - value);
        _transfer(from, to, value);
        return true;
    }
}