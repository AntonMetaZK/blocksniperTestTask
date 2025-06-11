// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Task1Factory.sol";
import "pancake-smart-contracts/projects/exchange-protocol/contracts/interfaces/IERC20.sol";
import "forge-std/console2.sol";

contract Task1FactoryForkTest is Test {
    address constant FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    receive() external payable {}

    Task1Factory task;

    function setUp() public {
        vm.createSelectFork(vm.envString("BSC_RPC_URL"));
        task = new Task1Factory(FACTORY, WBNB);
        vm.deal(address(this), 5 ether);

        console2.log("SETUP:");
        console2.log("Forked from:", vm.envString("BSC_RPC_URL"));
        console2.log("Test contract address:", address(this));
        console2.log("ETH balance:", address(this).balance);
        console2.log("Block number:", block.number);
        console2.log("Block timestamp:", block.timestamp);
    }

    function testBuyExactOut() public {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = BUSD;

        uint256 amountOut = 10e18;
        uint256 deadline = block.timestamp + 2 minutes;

        console2.log("==== TEST: buyExactOut ====");
        console2.log("Test contract address:", address(this));
        console2.log("Initial ETH balance:", address(this).balance);
        console2.log("WBNB:", WBNB);
        console2.log("BUSD:", BUSD);
        console2.log("Amount of BUSD to buy:", amountOut / 1e18, "BUSD");
        console2.log("Max ETH to spend (msg.value):", 1 ether / 1e18, "BNB");

        uint256 balBefore = address(this).balance;
        uint256[] memory amts = task.buyExactOut{value: 1 ether}(amountOut, path, address(this), deadline);

        console2.log("Call returned amts:");
        for (uint256 i = 0; i < amts.length; i++) {
            console2.log("  amts[", i, "] =", amts[i]);
        }

        uint256 balAfter = address(this).balance;
        uint256 tokenAfter = IERC20(BUSD).balanceOf(address(this));
        console2.log("Final ETH balance:", balAfter);
        console2.log("Final BUSD balance:", tokenAfter);

        assertEq(IERC20(BUSD).balanceOf(address(this)), amountOut, "wrong token amt");
        assertGe(balBefore - amts[0], 0, "no refund");
        console2.log("Test completed OK!");
    }
}
