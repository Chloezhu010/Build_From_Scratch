// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Math} from "../src/lib/Math.sol";

contract MathTest is Test {
    // Test min
    function test_min() public pure {
        assertEq(Math.min(1, 2), 1);
        assertEq(Math.min(2, 1), 1);
        assertEq(Math.min(0, 0), 0);
        assertEq(Math.min(type(uint256).max, type(uint256).max), type(uint256).max);
        assertEq(Math.min(type(uint256).min, type(uint256).min), type(uint256).min);
        assertEq(Math.min(type(uint256).max, type(uint256).min), type(uint256).min);
        assertEq(Math.min(type(uint256).min, type(uint256).max), type(uint256).min);
    }

    // Test max
    function test_max() public pure {
        assertEq(Math.max(1, 2), 2);
        assertEq(Math.max(2, 1), 2);
        assertEq(Math.max(0, 0), 0);
        assertEq(Math.max(type(uint256).max, type(uint256).max), type(uint256).max);
        assertEq(Math.max(type(uint256).min, type(uint256).min), type(uint256).min);
        assertEq(Math.max(type(uint256).max, type(uint256).min), type(uint256).max);
        assertEq(Math.max(type(uint256).min, type(uint256).max), type(uint256).max);
    }

    // Test sqrt
    function test_sqrt() public pure {
        assertEq(Math.sqrt(0), 0);
        assertEq(Math.sqrt(1), 1);
        assertEq(Math.sqrt(2), 1);
        assertEq(Math.sqrt(3), 1);
        assertEq(Math.sqrt(4), 2);
        assertEq(Math.sqrt(5), 2);
        assertEq(Math.sqrt(9), 3);
        assertEq(Math.sqrt(225), 15);
        assertEq(Math.sqrt(100), 10);
        assertEq(Math.sqrt(10**18), 10**9);
        assertEq(Math.sqrt(type(uint256).max), 340282366920938463463374607431768211455);
    }

    // Test quote
    function test_quote() public pure {
        uint256 large = 10**18;
        uint256 small = 10**9;

        assertEq(Math.quote(100, 100, 100), 100);
        assertEq(Math.quote(100, 100, 200), 200);
        assertEq(Math.quote(100, 200, 100), 50);
        assertEq(Math.quote(3, 5, 10), 6);
        assertEq(Math.quote(1, 2000, 1000), 0); // precision loss
        assertEq(Math.quote(small, small, small), small);
        assertEq(Math.quote(large, large, large), large);
        assertEq(Math.quote(large, small, small), large);
    }

    // function test_overflow_min() public pure {
    //     assertEq(Math.min(type(uint256).max, type(uint256).max + 1), type(uint256).max);
    //     assertEq(Math.min(type(uint256).min, type(uint256).min - 1), type(uint256).min);
    //     assertEq(Math.min(type(uint256).max, type(uint256).min - 1), type(uint256).min);
    //     assertEq(Math.min(type(uint256).min, type(uint256).max + 1), type(uint256).min);
    // }

    // function test_overflow_max() public pure {
    //     assertEq(Math.max(type(uint256).max, type(uint256).max + 1), type(uint256).max);
    //     assertEq(Math.max(type(uint256).min, type(uint256).min - 1), type(uint256).min);
    //     assertEq(Math.max(type(uint256).max, type(uint256).min - 1), type(uint256).max);
    //     assertEq(Math.max(type(uint256).min, type(uint256).max + 1), type(uint256).max);
    // }
}