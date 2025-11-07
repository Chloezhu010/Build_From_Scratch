// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/SimpleDEXPair.sol";
import "../src/SimpleDEXERC20.sol";
import "../src/lib/Math.sol";


contract TestERC20 is SimpleDEXERC20 {
    function mint(address to, uint value) public {
        _mint(to, value);
    }

    function burn(address from, uint value) public {
        _burn(from, value);
    }
}

contract SimpleDEXPairTest is Test {
    SimpleDEXPair public pair;
    TestERC20 public token0;
    TestERC20 public token1;

    address user1 = address(0x11);
    address user2 = address(0x22);

    function setUp() public {
    // create new tokens
        token0 = new TestERC20();
        token1 = new TestERC20();
    // create new pair
        pair = new SimpleDEXPair();
        pair.initialize(address(token0), address(token1));
    // fund users with tokens
        // user1: 1000 token0, 1000 token1
        token0.mint(user1, 1000);
        token1.mint(user1, 1000);
        // user2: 2000 token0, 2000 token1
        token0.mint(user2, 2000);
        token1.mint(user2, 2000);
    }

    function test_initial_state() public view {
       // pair should have 0 reserves
       (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
       assertEq(reserve0, 0);
       assertEq(reserve1, 0);
       // pair should have 0 total supply
       assertEq(pair.totalSupply(), 0);
       // pair should have 0 balance of tokens
       assertEq(token0.balanceOf(address(pair)), 0);
       assertEq(token1.balanceOf(address(pair)), 0);
       
       // user1 should have 1000 token0 and 1000 token1
       assertEq(token0.balanceOf(user1), 1000);
       assertEq(token1.balanceOf(user1), 1000);
       // user2 should have 2000 token0 and 2000 token1
       assertEq(token0.balanceOf(user2), 2000);
       assertEq(token1.balanceOf(user2), 2000);
    }

    // function test_first_mint() public {
    //     // user2 add 1000 token0, 1500 token1 to the pair
    //     vm.startPrank(user2);
    //     console.log("user2 token0 init balance:", token0.balanceOf(user2));
    //     console.log("user2 token1 init balance:", token1.balanceOf(user2));

    //     token0.transfer(address(pair), 1000);
    //     console.log("user2 token0 balance:", token0.balanceOf(user2));
    //     token1.transfer(address(pair), 1500);
    //     console.log("user2 token1 balance:", token1.balanceOf(user2));
        
    //     // user2 should have 1000 token0 and 500 token1
    //     assertEq(token0.balanceOf(user2), 1000);
    //     assertEq(token1.balanceOf(user2), 500);
    //     // pair should have 1000 token0 and 1500 token1
    //     assertEq(token0.balanceOf(address(pair)), 1000);
    //     assertEq(token1.balanceOf(address(pair)), 1500);
    //     // pair mint LP token to user2
    //     uint LP_token = pair.mint(user2);
    //     console.log("LP token mint to user2: ", LP_token);
    //     // user2 should have 224 LP tokens
    //     uint LP_token_cal = Math.sqrt(1000 * 1500) - 1000;
    //     assertEq(pair.balanceOf(user2), LP_token_cal);

    //     vm.stopPrank();
    // }

    // function test_second_mint() public {
    // // act as user2, send 1000 token0, 1500 token1 to the pair
    //     vm.startPrank(user2);
    //     token0.transfer(address(pair), 1000);
    //     console.log("user2 token0 balance:", token0.balanceOf(user2));
    //     token1.transfer(address(pair), 1500);
    //     console.log("user2 token1 balance:", token1.balanceOf(user2));
    //     // pair mint LP token
    //     uint LP_token = pair.mint(user2);
    //     console.log("LP token mint to user2: ", LP_token);
    //     // user2 should have 224 LP tokens
    //     uint LP_token_cal = Math.sqrt(1000 * 1500) - 1000;
    //     assertEq(pair.balanceOf(user2), LP_token_cal);
    //     vm.stopPrank();
    // // check LP total supply
    //     uint LP_totalSupply = pair.totalSupply();
    //     console.log("LP total supply: ", LP_totalSupply);
    // // act as user1, send 500 token0, 600 token1 to the pair
    //     vm.startPrank(user1);
    //     token0.transfer(address(pair), 500);
    //     console.log("user1 token0 balance: ", token0.balanceOf(user1));
    //     token1.transfer(address(pair), 600);
    //     console.log("user1 token1 balance: ", token1.balanceOf(user1));
    //     // pair mint LP token to user1
    //     uint LP_token_2 = pair.mint(user1);
    //     console.log("LP token mint to user1: ", LP_token_2);
    //     // user1 should have LP tokens;
    //     uint LP_token_cal_2 = Math.min(500 * LP_totalSupply / 1000, 600 * LP_totalSupply / 1500);
    //     assertEq(pair.balanceOf(user1), LP_token_cal_2);
    //     vm.stopPrank();
    // }

    // function test_burn() public {
    // // user2 add liquidity
    //     vm.startPrank(user2);
    //     token0.transfer(address(pair), 1000);
    //     token1.transfer(address(pair), 1500);
    //     console.log("user2 token0 balance post transfer: ", token0.balanceOf(user2));
    //     console.log("user2 token1 balance post transfer: ", token1.balanceOf(user2));
    //     uint liquidity = pair.mint(user2);
    //     console.log("LP token minted to user2: ", liquidity);
    // // user2 transfers LP token back to the pair
    //     pair.transfer(address(pair), liquidity);
    // // burn LP token
    //     (uint amount0, uint amount1) = pair.burn(address(user2));
    //     console.log("return amount0 to user2: ", amount0);
    //     console.log("return amount1 to user2: ", amount1);
    // // verify user2 received tokens back
    //     console.log("user2 balance0: ", token0.balanceOf(user2));
    //     console.log("user2 balance1: ", token1.balanceOf(user2));
    // // verify user2 no longer has LP tokens
    //     assertEq(pair.balanceOf(user2), 0);
    //     console.log("user2 LP token balance: ", pair.balanceOf(user2));
    //     vm.stopPrank();
    // }

    // function test_second_burn() public {
    // // act as user2, send 1000 token0, 1500 token1 to the pair
    //     vm.startPrank(user2);
    //     token0.transfer(address(pair), 1000);
    //     token1.transfer(address(pair), 1500);
    //     console.log("post-transfer user2 token0 balance:", token0.balanceOf(user2));
    //     console.log("post-transfer user2 token1 balance:", token1.balanceOf(user2));
    //     // pair mint LP token
    //     uint LP_token = pair.mint(user2);
    //     console.log("   LP token mint to user2: ", LP_token);
    //     // user2 should have 224 LP tokens
    //     uint LP_token_cal = Math.sqrt(1000 * 1500) - 1000;
    //     assertEq(pair.balanceOf(user2), LP_token_cal);
    //     vm.stopPrank();
    // // check LP total supply
    //     uint LP_totalSupply = pair.totalSupply();
    //     console.log("   LP total supply: ", LP_totalSupply);
    // // act as user1, send 400 token0, 600 token1 to the pair
    //     vm.startPrank(user1);
    //     token0.transfer(address(pair), 400);
    //     token1.transfer(address(pair), 600);
    //     console.log("post-transfer user1 token0 balance: ", token0.balanceOf(user1));
    //     console.log("post-transfer user1 token1 balance: ", token1.balanceOf(user1));
    //     // pair mint LP token to user1
    //     uint LP_token_2 = pair.mint(user1);
    //     console.log("   LP token mint to user1: ", LP_token_2);
    //     console.log("post-deposit user1 token0 balance: ", token0.balanceOf(user1));
    //     console.log("post-deposit user1 token1 balance: ", token1.balanceOf(user1));
    //     // user1 should have LP tokens;
    //     uint LP_token_cal_2 = Math.min(500 * LP_totalSupply / 1000, 600 * LP_totalSupply / 1500);
    //     assertEq(pair.balanceOf(user1), LP_token_cal_2);
    // // user1 transfer LP token back to the pair
    //     pair.transfer(address(pair), LP_token_2);
    // // burn LP token
    //     (uint amount0, uint amount1) = pair.burn(address(user1));
    //     console.log("   return amount0 to user1: ", amount0);
    //     console.log("   return amount1 to user1: ", amount1);
    // // verify user1 received tokens back
    //     console.log("final user1 balance0: ", token0.balanceOf(user1));
    //     console.log("final user1 balance1: ", token1.balanceOf(user1));
    //     vm.stopPrank();
    // }

    function test_mint_zero_LP() public {
        vm.startPrank(user1);
        token0.transfer(address(pair), 10);
        token1.transfer(address(pair), 10);
        vm.stopPrank();

        vm.expectRevert("SimpleDEXPair: INSUFFICIENT_LIQUIDITY_MINTED");
        pair.mint(user1);
    }

    function test_burn_zero_LP() public {
        vm.prank(user1);
        vm.expectRevert("SimpleDEXPair: INSUFFICIENT_LIQUIDITY_MINTED");
        pair.burn(user1);
    }

    function test_reserves_after_mint() public {
        vm.startPrank(user2);
        token0.transfer(address(pair), 1000);
        token1.transfer(address(pair), 1500);
        vm.stopPrank();

        pair.mint(user2);
        (uint112 r0, uint112 r1,) = pair.getReserves();
        assertEq(r0, 1000);
        assertEq(r1, 1500);
    }

    function test_reserves_after_burn() public {
        // mint
        vm.startPrank(user2);
        token0.transfer(address(pair), 1000);
        token1.transfer(address(pair), 1500);
        uint liquidity = pair.mint(user2);
        vm.stopPrank();
        // burn
        vm.startPrank(user2);
        pair.transfer(address(pair), liquidity);
        pair.burn(user2);
        vm.stopPrank();
        // check reserves (shouldn't be 0 cause min_liquidity is locked)
        (uint112 r0, uint112 r1,) = pair.getReserves();
        assertEq(r0, 817);
        assertEq(r1, 1226);
    }
}