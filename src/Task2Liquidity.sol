// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "pancake-smart-contracts/projects/exchange-protocol/contracts/interfaces/IPancakeRouter02.sol";
import "pancake-smart-contracts/projects/exchange-protocol/contracts/interfaces/IPancakeFactory.sol";
import "pancake-smart-contracts/projects/exchange-protocol/contracts/interfaces/IPancakePair.sol";

import "pancake-smart-contracts/projects/exchange-protocol/contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "forge-std/console.sol";

contract Task2Liquidity is ReentrancyGuard {
    IPancakeRouter02 public immutable router;
    address public immutable WBNB;

    constructor(IPancakeRouter02 _router) {
        router = _router;
        WBNB = _router.WETH();
    }
    function buyAndPool(
        uint256 amountTokenDesired,
        address[] calldata path,
        uint256 deadline
    ) external payable nonReentrant returns (uint256 liquidity) {
        require(path.length == 2, "BAD_PATH");
        require(path[0] == WBNB, "path[0]!=WBNB");

        uint[] memory amounts = router.swapETHForExactTokens{value: msg.value}(
            amountTokenDesired,
            path,
            address(this),
            deadline
        );
        uint256 bnbSpent = amounts[0];
        uint256 bnbLeft = msg.value - bnbSpent;

        address pair = IPancakeFactory(router.factory()).getPair(path[1], WBNB);
        require(pair != address(0), "NO_PAIR");
        (uint112 reserve0, uint112 reserve1, ) = IPancakePair(pair)
            .getReserves();
        (uint112 reserveToken, uint112 reserveBNB) = (path[1] < WBNB)
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        uint256 optimalTokenAmount = (bnbLeft * reserveToken) / reserveBNB;
        uint256 usedTokenAmount = optimalTokenAmount > amountTokenDesired
            ? amountTokenDesired
            : optimalTokenAmount;
        uint256 usedBNBAmount = (usedTokenAmount * reserveBNB) / reserveToken;

        uint256 minTokenAmount = (usedTokenAmount * 995) / 1000;
        uint256 minBNBAmount = (usedBNBAmount * 995) / 1000;

        IERC20(path[1]).approve(address(router), usedTokenAmount);

        // Add liquidity
        (, , liquidity) = router.addLiquidityETH{value: usedBNBAmount}(
            path[1],
            usedTokenAmount,
            minTokenAmount,
            minBNBAmount,
            msg.sender,
            deadline
        );

        _refundDust(IERC20(path[1]), msg.sender);
    }

    /* --------------------------INTERNAL------------------------------------------- */
    function _refundDust(IERC20 token, address to) internal {
        uint256 dustBNB = address(this).balance;
        if (dustBNB > 0) payable(to).transfer(dustBNB);

        uint256 dustToken = token.balanceOf(address(this));
        if (dustToken > 0) token.transfer(to, dustToken);
    }

    receive() external payable {}
}
