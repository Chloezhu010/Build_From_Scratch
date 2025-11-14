// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/SimpleDEXPair.sol";
import "../src/SimpleDEXFactory.sol";
import "../src/SimpleDEXERC20.sol";
import "../src/lib/Math.sol";

contract TestERC20 is SimpleDEXERC20 {
    function mint(address to, uint value) public {
        _mint(to, value);
    }
}

contract SimpleDEXFactoryTest is Test {
    SimpleDEXFactory public factory;
    TestERC20 public tokenA;
    TestERC20 public tokenB;
    TestERC20 public tokenC;

    function setUp() public {
        // deploy factory
        factory = new SimpleDEXFactory();
        // deploy test tokens
        tokenA = new TestERC20();
        tokenB = new TestERC20();
        tokenC = new TestERC20();
    }

    // create a single pair
    function test_createPair() public {
        address pair = factory.createPair(address(tokenA), address(tokenB));
        console.log("pair address: ", pair);
        assertNotEq(pair, address(0));
    }

    // test pair address is deterministic
    function test_createPair_deterministic() public {
        factory.createPair(address(tokenA), address(tokenB));
        vm.expectRevert("SimpleDEXFactory: PAIR_EXISTS");
        factory.createPair(address(tokenA), address(tokenB));
    }

    // test pair is registered in mapping (both directions)
    function test_createPair_mapping() public {
        address pair = factory.createPair(address(tokenA), address(tokenB));

        address pairAB = factory.getPair(address(tokenA), address(tokenB));
        address pairBA = factory.getPair(address(tokenB), address(tokenA));
        assertEq(pairAB, pair);
        assertEq(pairBA, pair);
    }

    // test pair is added to allPairs array
    function test_createPair_array() public {
        // verify all pairs length
        uint initLen = factory.allPairsLength();
        address pair = factory.createPair(address(tokenA), address(tokenB));
        console.log("created pair address: ", pair);
        uint newLen = factory.allPairsLength();
        assertEq(newLen, initLen + 1);

        // verify pair is in array
        address storedPair = factory.allPairs(newLen - 1);
        console.log("stored pair address: ", storedPair);
        assertEq(storedPair, pair);
    }

    // test tokens are sorted correctly
    function test_createPair_tokenSorting() public {
        address pairAddr = factory.createPair(address(tokenA), address(tokenB));
        SimpleDEXPair pair = SimpleDEXPair(pairAddr);

        address token0 = pair.token0();
        address token1 = pair.token1();

        assertTrue(token0 < token1);
        console.log("address of token0: ", token0);
        console.log("address of token1: ", token1);
    }

    // test errors
    function test_createPair_errors() public {
        vm.expectRevert("SimpleDEXFactory: IDENTICAL_ADDRESS");
        factory.createPair(address(tokenA), address(tokenA));

        vm.expectRevert("SimpleDEXFactory: ZERO_ADDRESS");
        factory.createPair(address(tokenA), address(0));

        factory.createPair(address(tokenA), address(tokenB));
        vm.expectRevert("SimpleDEXFactory: PAIR_EXISTS");
        factory.createPair(address(tokenB), address(tokenA));
    }
}