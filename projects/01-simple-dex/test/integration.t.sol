// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/SimpleDEXFactory.sol";
import "../src/SimpleDEXRouter.sol";
import "../src/SimpleDEXPair.sol";
import "../src/SimpleDEXERC20.sol";

// Test ERC20 token for testing
contract TestToken is SimpleDEXERC20 {
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        decimals = 18;
    }

    function mint(address to, uint value) public {
        _mint(to, value);
    }

    function burn(address from, uint value) public {
        _burn(from, value);
    }
}

contract IntegrationTest is Test {
    SimpleDEXFactory public factory;
    SimpleDEXRouter public router;
    TestToken public tokenA;
    TestToken public tokenB;
    TestToken public tokenC;

    address user1 = address(0x11);
    address user2 = address(0x22);
    address user3 = address(0x33);

    function setUp() public {
        factory = new SimpleDEXFactory();
        router = new SimpleDEXRouter(address(factory));
        
        // Create test tokens
        tokenA = new TestToken("TokenA", "TA");
        tokenB = new TestToken("TokenB", "TB");
        tokenC = new TestToken("TokenC", "TC");

        // Mint tokens to users
        tokenA.mint(user1, 10000e18);
        tokenB.mint(user1, 10000e18);
        tokenC.mint(user1, 10000e18);

        tokenA.mint(user2, 10000e18);
        tokenB.mint(user2, 10000e18);
        tokenC.mint(user2, 10000e18);

        tokenA.mint(user3, 10000e18);
        tokenB.mint(user3, 10000e18);
        tokenC.mint(user3, 10000e18);
    }

    function testCompleteLiquidityFlow() public {
        // Approve router to spend tokens
        vm.startPrank(user1);
        tokenA.approve(address(router), type(uint).max);
        tokenB.approve(address(router), type(uint).max);
        vm.stopPrank();

        // Add liquidity to a new pair
        vm.startPrank(user1);
        (uint amountA, uint amountB, uint liquidity) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1000e18,      // amountADesired
            1000e18,      // amountBDesired
            990e18,       // amountAMin
            990e18,       // amountBMin
            user1,        // to
            block.timestamp + 1000  // deadline
        );
        vm.stopPrank();

        // Verify liquidity was added
        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        SimpleDEXPair pair = SimpleDEXPair(pairAddress);
        
        assertEq(amountA, 1000e18);  // Exact amountA provided
        assertEq(amountB, 1000e18);  // Exact amountB provided
        assertGt(liquidity, 0);      // Liquidity minted
        
        // Verify user1 has LP tokens
        uint lpBalance = pair.balanceOf(user1);
        assertGt(lpBalance, 0);
        
        // Verify reserves in the pair
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        assertEq(uint(reserve0), 1000e18);
        assertEq(uint(reserve1), 1000e18);
        
        console.log("Liquidity added successfully");
        console.log("User LP balance:", lpBalance / 1e18);
    }

    function testCompleteSwapFlow() public {
        // Create pair and add liquidity first
        vm.startPrank(user1);
        tokenA.approve(address(router), type(uint).max);
        tokenB.approve(address(router), type(uint).max);
        
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1000e18,
            1000e18,
            990e18,
            990e18,
            user1,
            block.timestamp + 1000
        );
        vm.stopPrank();

        // User2 swaps tokens
        vm.startPrank(user2);
        tokenA.approve(address(router), type(uint).max);
        
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        
        uint[] memory amounts = router.getAmountsOut(100e18, path);
        uint amountOut = amounts[1];
        
        uint256 tokenABefore = tokenA.balanceOf(user2);
        uint256 tokenBBefore = tokenB.balanceOf(user2);
        
        router.swapExactTokensforTokens(
            100e18,           // amountIn
            amountOut * 99 / 100,  // amountOutMin (with slippage)
            path,
            user2,
            block.timestamp + 1000  // deadline
        );
        
        uint256 tokenAAfter = tokenA.balanceOf(user2);
        uint256 tokenBAfter = tokenB.balanceOf(user2);
        vm.stopPrank();

        // Verify swap results
        assertEq(tokenAAfter, tokenABefore - 100e18);  // User2 spent 100 tokenA
        assertGt(tokenBAfter, tokenBBefore);           // User2 received tokenB
        assertEq(tokenBAfter - tokenBBefore, amountOut); // Amount received matches expected
        
        console.log("Swap completed successfully");
        console.log("Amount of tokenB received:", amountOut / 1e18);
    }

    function testLiquidityRemovalFlow() public {
        // Add liquidity first
        vm.startPrank(user1);
        tokenA.approve(address(router), type(uint).max);
        tokenB.approve(address(router), type(uint).max);
        
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1000e18,
            1000e18,
            990e18,
            990e18,
            user1,
            block.timestamp + 1000
        );
        vm.stopPrank();

        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        SimpleDEXPair pair = SimpleDEXPair(pairAddress);
        uint lpBalance = pair.balanceOf(user1);
        uint initialTokenABalance = tokenA.balanceOf(user1);
        uint initialTokenBBalance = tokenB.balanceOf(user1);

        // Remove liquidity
        vm.startPrank(user1);
        pair.approve(address(router), type(uint).max);
        
        (uint amountA, uint amountB) = router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            lpBalance / 2,    // Remove half liquidity
            490e18,           // amountAMin (with slippage)
            490e18,           // amountBMin (with slippage)
            user1,
            block.timestamp + 1000  // deadline
        );
        vm.stopPrank();

        // Verify liquidity removal
        uint finalTokenABalance = tokenA.balanceOf(user1);
        uint finalTokenBBalance = tokenB.balanceOf(user1);
        uint remainingLpBalance = pair.balanceOf(user1);

        assertEq(finalTokenABalance, initialTokenABalance + amountA);
        assertEq(finalTokenBBalance, initialTokenBBalance + amountB);
        assertEq(remainingLpBalance, lpBalance / 2);  // Half LP tokens should remain
        
        console.log("Liquidity removal completed successfully");
        console.log("Amount A returned:", amountA / 1e18);
        console.log("Amount B returned:", amountB / 1e18);
    }

    function testMultiHopSwap() public {
        // Create pair A-B and add liquidity
        vm.startPrank(user1);
        tokenA.approve(address(router), type(uint).max);
        tokenB.approve(address(router), type(uint).max);
        tokenC.approve(address(router), type(uint).max);
        
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1000e18,
            1000e18,
            990e18,
            990e18,
            user1,
            block.timestamp + 1000
        );
        
        // Create pair B-C and add liquidity
        router.addLiquidity(
            address(tokenB),
            address(tokenC),
            1000e18,
            1000e18,
            990e18,
            990e18,
            user1,
            block.timestamp + 1000
        );
        vm.stopPrank();

        // User2 swaps A -> B -> C
        vm.startPrank(user2);
        tokenA.approve(address(router), type(uint).max);
        
        address[] memory path = new address[](3);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);
        
        uint[] memory amounts = router.getAmountsOut(100e18, path);
        uint amountOut = amounts[2];
        
        uint256 tokenABefore = tokenA.balanceOf(user2);
        uint256 tokenCBefore = tokenC.balanceOf(user2);
        
        router.swapExactTokensforTokens(
            100e18,           // amountIn
            amountOut * 99 / 100,  // amountOutMin (with slippage)
            path,
            user2,
            block.timestamp + 1000  // deadline
        );
        
        uint256 tokenAAfter = tokenA.balanceOf(user2);
        uint256 tokenCAfter = tokenC.balanceOf(user2);
        vm.stopPrank();

        // Verify multi-hop swap results
        assertEq(tokenAAfter, tokenABefore - 100e18);  // User2 spent 100 tokenA
        assertGt(tokenCAfter, tokenCBefore);           // User2 received tokenC
        assertEq(tokenCAfter - tokenCBefore, amountOut); // Amount received matches expected
        
        console.log("Multi-hop swap completed successfully");
        console.log("Amount of tokenC received:", amountOut / 1e18);
    }

    function testFactoryRouterIntegration() public {
        // Test that factory and router work together properly
        address expectedPair = router.pairFor(address(tokenA), address(tokenB));
        console.log("pair address: ", expectedPair);

        // Add liquidity to create pair
        vm.startPrank(user1);
        tokenA.approve(address(router), type(uint).max);
        tokenB.approve(address(router), type(uint).max);
        
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1000e18,
            1000e18,
            990e18,
            990e18,
            user1,
            block.timestamp + 1000
        );
        vm.stopPrank();

        // Check that pair was created by factory
        address actualPair = factory.getPair(address(tokenA), address(tokenB));
        address expectedPairAfter = router.pairFor(address(tokenA), address(tokenB));
        
        assertNotEq(actualPair, address(0));      // Pair should exist now
        assertEq(actualPair, expectedPairAfter);  // Both should return same address
        assertEq(actualPair, expectedPair);       // Should match pre-calculated address

        // Verify pair properties
        SimpleDEXPair pair = SimpleDEXPair(actualPair);
        assertEq(pair.token0(), address(tokenA) < address(tokenB) ? address(tokenA) : address(tokenB));
        assertEq(pair.token1(), address(tokenA) < address(tokenB) ? address(tokenB) : address(tokenA));
        
        console.log("Factory-Router integration test successful");
    }

    function testDeadlineRejection() public {
        // Set up liquidity
        vm.startPrank(user1);
        tokenA.approve(address(router), type(uint).max);
        tokenB.approve(address(router), type(uint).max);
        
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1000e18,
            1000e18,
            990e18,
            990e18,
            user1,
            block.timestamp + 1000
        );
        vm.stopPrank();

        // Try to swap with expired deadline
        vm.startPrank(user2);
        tokenA.approve(address(router), type(uint).max);
        
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        
        vm.warp(block.timestamp + 2000); // Warp to after deadline
        
        vm.expectRevert("SimpleDEXRouter: EXPIRED");
        router.swapExactTokensforTokens(
            100e18,           // amountIn
            90e18,            // amountOutMin
            path,
            user2,
            block.timestamp - 100  // expired deadline
        );
        vm.stopPrank();
        
        console.log("Deadline rejection test successful");
    }

    function testInsufficientLiquidity() public {
        // Try to swap more than available liquidity
        vm.startPrank(user1);
        tokenA.approve(address(router), type(uint).max);
        tokenB.approve(address(router), type(uint).max);
        
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            10e18,           // Small liquidity
            10e18,           // Small liquidity
            90e18,
            90e18,
            user1,
            block.timestamp + 1000
        );
        vm.stopPrank();

        // Try to swap much more than available liquidity
        vm.startPrank(user2);
        tokenA.approve(address(router), type(uint).max);
        
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        
        // Calculate expected amounts - should fail because of insufficient output
        uint[] memory amounts = router.getAmountsOut(90e18, path); // Try to swap more than liquidity
        console.log("amounts[0]: ", amounts[0]/ 1e18);
        console.log("amounts[1]: ", amounts[1]/ 1e18);
        vm.expectRevert(); // Should fail in pair contract due to insufficient reserves
        router.swapExactTokensforTokens(
            90e18,           // amountIn - more than available liquidity
            88e18,       // amountOutMin
            path,
            user2,
            block.timestamp + 1000
        );
        vm.stopPrank();
        
        console.log("Insufficient liquidity protection test successful");
    }
}