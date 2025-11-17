// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SimpleDEXERC20.sol";
import "../src/SimpleDEXFactory.sol";
import "../src/SimpleDEXPair.sol";
import "../src/SimpleDEXRouter.sol";

contract DeploySimpleDEX is Script {
    function run() external {
        uint256 deployerPk = vm.envUint("PRIVATE_KEY");
        // address weth = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14; // Sepolia WETH

        vm.startBroadcast(deployerPk);
        // deploy factory
        SimpleDEXFactory factory = new SimpleDEXFactory();
        // deploy router
        SimpleDEXRouter router = new SimpleDEXRouter(address(factory));
        vm.stopBroadcast();
        
        console.log("Factory deployment at: ", address(factory));
        console.log("Router deployment at: ", address(router));
    }
}
