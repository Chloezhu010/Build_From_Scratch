// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/SimpleDEXRouter.sol";
import "../src/SimpleDEXFactory.sol";
import "../src/SimpleDEXPair.sol";
import "../src/SimpleDEXERC20.sol";

contract TestERC20 is SimpleDEXERC20 {
    string public tokenName;
    string public tokenSymbol;

    constructor (string memory _name, string memory _symbol){
        tokenName = _name;
        tokenSymbol = _symbol;
    }

    function mint(address to, uint amount) public {
        _mint(to, amount);
    }
}

contract SimpleDEXRouterTest is Test {
    // contracts
    SimpleDEXFactory public factory;
    SimpleDEXRouter public router;
    TestERC20 public tokenA;
    TestERC20 public tokenB;
    TestERC20 public tokenC;

    // users
    address user1 = address(0x11);
    address user2 = address(0x22);

    function setUp() public {
        // deploy factory
        factory = new SimpleDEXFactory();
        address factoryAddr = address(factory);

        // deploy router
        router = new SimpleDEXRouter(factoryAddr);

        // deploy test tokens
        tokenA = new TestERC20("TokenA", "TA");
        tokenB = new TestERC20("TokenB", "TB");
        tokenC = new TestERC20("TokenC", "TC");

        // mint test tokens to users
        tokenA.mint(user1, 10_000 ether);
        tokenB.mint(user1, 10_000 ether);
        tokenC.mint(user1, 10_000 ether);

        tokenA.mint(user2, 10_000 ether);
        tokenB.mint(user2, 10_000 ether);
        tokenC.mint(user2, 10_000 ether);
    }

    // function test_getAmountOut_basic() public view {
    //     uint output = router.getAmountOut(100, 1000, 1000);
    //     assertGt(output, 80);
    //     assertLt(output, 100);
    //     console.log("getAmountOut for input of 100: ", output);
    // }

    // function test_getAmountOut_highReserve() public view {
    //     uint output = router.getAmountOut(100, 100000, 100000);
    //     assertGt(output, 90);
    //     assertLt(output, 100);
    //     console.log("getAmountOut for input of 100: ", output);
    // }

    // function test_getAmountOut_reserveZero() public {
    //     vm.expectRevert("SimpleDEXRouter: INSUFFICIENT_LIQUIDITY");
    //     router.getAmountOut(100, 0, 1000);
    // }

    // function test_getAmountsOut_singleHop() public {
    //     // setup: create tokenA-B pair with reserves of 1000 tokenA/ 1000 tokenB
    //     vm.startPrank(user1);
    //     tokenA.approve(address(router), 1000 ether);
    //     tokenB.approve(address(router), 1000 ether);
    //     router.addLiquidity(
    //         address(tokenA), 
    //         address(tokenB), 
    //         1000 ether, 1000 ether, 
    //         990 ether, 990 ether, 
    //         user1,
    //         block.timestamp + 1000);
    //     vm.stopPrank();
    //     // cal amounts for single hop
    //     address[] memory path = new address[](2);
    //     path[0] = address(tokenA);
    //     path[1] = address(tokenB);
    //     uint[] memory amounts = router.getAmountsOut(100 ether, path);
        
    //     assertEq(amounts[0], 100 ether);
    //     assertGt(amounts[1], 80 ether);
    //     assertLt(amounts[1], 100 ether);
    // }

    function test_getAmountsOut_multiHop() public {
        // setup tokenA-b, tokenB-C
        vm.startPrank(user1);
        tokenA.approve(address(router), 1000 ether);
        tokenB.approve(address(router), 1000 ether);
        router.addLiquidity(
            address(tokenA), 
            address(tokenB), 
            1000 ether, 1000 ether, 
            990 ether, 990 ether, 
            user1,
            block.timestamp + 1000);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenB.approve(address(router), 1000 ether);
        tokenC.approve(address(router), 1000 ether);
        router.addLiquidity(
            address(tokenB), 
            address(tokenC), 
            1000 ether, 1000 ether, 
            990 ether, 990 ether, 
            user1,
            block.timestamp + 1000);
        vm.stopPrank();

        // calculate amounts for multi-hop
        address[] memory path = new address[](3);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);

        uint[] memory amounts = router.getAmountsOut(100 ether, path);
        assertEq(amounts[0], 100 ether);
        assertGt(amounts[1], 80 ether);
        assertGt(amounts[2], 80 ether);
        assertLt(amounts[2], 100 ether);
        console.log("amounts 0: ", amounts[0]);
        console.log("amounts 1: ", amounts[1]);
        console.log("amounts 2: ", amounts[2]);
    }

    function test_addLiquidity_firstDeposit() public {
        vm.startPrank(user1);
        // approve tokens
        tokenA.approve(address(router), 1000 ether);
        tokenB.approve(address(router), 1000 ether);

        // add liquidity
        (uint amountA, uint amountB, uint liquidity) = router.addLiquidity(
            address(tokenA), 
            address(tokenB), 
            1000 ether, 1000 ether,
            900 ether, 900 ether,
            user1,
            block.timestamp + 1000);
        console.log("amountA: ", amountA);
        console.log("amountB: ", amountB);
        console.log("liquidity: ", liquidity);

        // verify all amounts used
        assertEq(amountA, 1000 ether);
        assertEq(amountB, 1000 ether);
        assertGt(liquidity, 900 ether);

        // verify LP tokens received
        address pair = router.pairFor(address(tokenA), address(tokenB));
        uint LpBalance = SimpleDEXERC20(pair).balanceOf(user1);
        console.log("LP balance: ", LpBalance);
        assertEq(LpBalance, liquidity);

        vm.stopPrank();
    }

    function test_addLiquidity_insufficient_slippage() public {
        vm.startPrank(user1);
        // approve tokens
        tokenA.approve(address(router), 1000 ether);
        tokenB.approve(address(router), 1000 ether);
        // add liquidity
        router.addLiquidity(
            address(tokenA), 
            address(tokenB), 
            1000 ether, 1000 ether,
            900 ether, 900 ether,
            user1,
            block.timestamp + 1000);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenA.approve(address(router), 2000 ether);
        tokenB.approve(address(router), 2000 ether);
        vm.expectRevert("SimpleDEXRouter: INSUFFICIENT_B_AMOUNT");
        router.addLiquidity(
            address(tokenA), 
            address(tokenB), 
            1000 ether, 2000 ether,
            900 ether, 2000 ether,
            user1,
            block.timestamp + 1000);
        vm.stopPrank();
    }

    function test_removeLiquidity() public {
        // user1 add liquidity
        vm.startPrank(user1);
        tokenA.approve(address(router), 10000 ether);
        tokenB.approve(address(router), 10000 ether);
        (,, uint liquidity) = router.addLiquidity(
            address(tokenA), 
            address(tokenB), 
            10000 ether, 10000 ether,
            9900 ether, 9900 ether,
            user1,
            block.timestamp + 1000);
        vm.stopPrank();
        // user2 add liquidity
        vm.startPrank(user2);
        tokenA.approve(address(router), 8000 ether);
        tokenB.approve(address(router), 8000 ether);
        router.addLiquidity(
            address(tokenA), 
            address(tokenB), 
            8000 ether, 8000 ether,
            7800 ether, 7800 ether,
            user1,
            block.timestamp + 1000);
        vm.stopPrank();
        // user2 swap tokenA for tokenB
        vm.startPrank(user2);
        tokenA.approve(address(router), 500 ether);
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        router.swapExactTokensforTokens(
            500, // amountIn
            480, // amountOutMin
            path, 
            user2,
            block.timestamp + 1000);
        vm.stopPrank();
        // // user2 swap tokenB for tokenA
        // vm.startPrank(user2);
        // tokenB.approve(address(router), 50 ether);
        // address[] memory path2 = new address[](2);
        // path2[0] = address(tokenB);
        // path2[1] = address(tokenA);
        // router.swapExactTokensforTokens(
        //     50, // amountIn
        //     48, // amountOutMin
        //     path2, 
        //     user2,
        //     block.timestamp + 1000);
        // vm.stopPrank();

        // user2 remove liquidity
        vm.startPrank(user1);
        address pair = router.pairFor(address(tokenA), address(tokenB));
        SimpleDEXERC20(pair).approve(address(router), liquidity);
        (uint amountA, uint amountB) = router.removeLiquidity(
            address(tokenA), 
            address(tokenB), 
            liquidity, 
            0, 0, // amountAMin, amountBMin
            user1, 
            block.timestamp + 1000);
        
        console.log("amountA: ", amountA);
        console.log("amountB: ", amountB);
        uint LpBalance = SimpleDEXERC20(pair).balanceOf(user1);
        // assertEq(LpBalance, 0);
        console.log("LP token balance: ", LpBalance);
        vm.stopPrank();
    }
}