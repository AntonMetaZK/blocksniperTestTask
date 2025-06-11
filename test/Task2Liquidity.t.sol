// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Task2Liquidity.sol";
import "pancake-smart-contracts/projects/exchange-protocol/contracts/interfaces/IPancakeRouter02.sol";
import "pancake-smart-contracts/projects/exchange-protocol/contracts/interfaces/IPancakeFactory.sol";
import "pancake-smart-contracts/projects/exchange-protocol/contracts/interfaces/IERC20.sol";

contract Task2LiquidityForkTest is Test {
    IPancakeRouter02 constant ROUTER =
        IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    Task2Liquidity pooler;
    receive() external payable {}

    function setUp() public {
        vm.createSelectFork(vm.envString("BSC_RPC_URL"));
        pooler = new Task2Liquidity(ROUTER);
        vm.deal(address(this), 3 ether);
    }
    function testBuyAndPool() public {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = BUSD;
        uint256 deadline = block.timestamp + 2 minutes;
        uint256 amountTok = 100e18;

        uint256 liq = pooler.buyAndPool{value: 3 ether}(
            amountTok,
            path,
            deadline
        );
        assertGt(liq, 0);

        address pair = IPancakeFactory(ROUTER.factory()).getPair(BUSD, WBNB);
        assertGt(IERC20(pair).balanceOf(address(this)), 0);
    }
}
