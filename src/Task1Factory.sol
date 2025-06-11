// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "pancake-smart-contracts/projects/exchange-protocol/contracts/interfaces/IWETH.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "pancake-smart-contracts/projects/exchange-protocol/contracts/interfaces/IPancakeFactory.sol";
import "pancake-smart-contracts/projects/exchange-protocol/contracts/interfaces/IPancakePair.sol";
import "forge-std/console.sol";

contract Task1Factory is ReentrancyGuard {
    address public immutable factory;
    IWETH public immutable WBNB;

    constructor(address _factory, address _wbnb) {
        factory = _factory;
        WBNB = IWETH(_wbnb);
    }

    function buyExactOut(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable nonReentrant returns (uint256[] memory amounts) {
        require(path.length == 2, "Only direct pairs supported");
        require(path[0] == address(WBNB), "path[0]!=WBNB");
        require(block.timestamp <= deadline, "DEADLINE");

        address pair = IPancakeFactory(factory).getPair(path[0], path[1]);
        require(pair != address(0), "PAIR_NOT_EXISTS");

        (uint112 reserve0, uint112 reserve1, ) = IPancakePair(pair)
            .getReserves();

        address token0 = IPancakePair(pair).token0();

        (uint reserveIn, uint reserveOut) = path[0] == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        require(amountOut < reserveOut, "INSUFFICIENT_LIQUIDITY");
        uint numerator = reserveIn * amountOut * 10000;
        uint denominator = (reserveOut - amountOut) * 9975;
        uint amountIn = (numerator / denominator) + 1;

        require(amountIn <= msg.value, "EXCESSIVE_INPUT");

        WBNB.deposit{value: amountIn}();
        WBNB.transfer(pair, amountIn);

        (uint amount0Out, uint amount1Out) = path[0] == token0
            ? (uint(0), amountOut)
            : (amountOut, uint(0));

        IPancakePair(pair).swap(amount0Out, amount1Out, to, new bytes(0));

        uint256 dust = msg.value - amountIn;
        if (dust > 0) payable(msg.sender).transfer(dust);

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;

        console.log("msg.value", msg.value);
        console.log("amountIn (BNB needed)", amountIn);
        console.log("amountOut (tokens bought)", amountOut);
        console.log("dust/refund", dust);
    }

    receive() external payable {}
}
