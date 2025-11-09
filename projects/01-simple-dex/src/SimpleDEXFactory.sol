// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/ISimpleDEXFactory.sol";
import "./interfaces/ISimpleDEXPair.sol";
import "./SimpleDEXPair.sol";

contract SimpleDEXFactory is ISimpleDEXFactory {
    mapping(address => mapping(address => address)) public pairs;
    address[] public allPairs;

    // get all pairs count
    function allPairsLength() external view returns (uint){
        return allPairs.length;
    }

    // get pair address based on the tokens' addresses
    function getPair(address tokenA, address tokenB) external view returns (address pair){
        return pairs[tokenA][tokenB];
    }

    // return pair address for tokenA-tokenB pool
    function createPair(address tokenA, address tokenB) external returns (address pair){
    // input validation
        require (tokenA != tokenB, "SimpleDEXFactory: IDENTICAL_ADDRESS");
    // sort tokens (canonical order)
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB): (tokenB, tokenA);
        require (token0 != address(0), "SimpleDEXFactory: ZERO_ADDRESS");
    // check if the pair already exists
        require(getPair[token0][token1] == address(0), "SimpleDEXFactory: PAIR_EXISTS");
    // deploy new SimpleDEXPair contract using create2
        // get the bytecode
        bytes memory bytecode = type(SimpleDEXPair).creationCode;
        // create salt from token address
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // deploy using CREATE2
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
    // initialize the pair
        ISimpleDEXPair(pair).initialize(token0, token1);
    // register pair in mapping (bidirectional)
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
    // store pair in the allPairs array
        allPairs.push(pair);
    // emit event
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}