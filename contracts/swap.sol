// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MSQLiquidityPool.sol";

contract MSQSwap {
    using SafeERC20 for IERC20;

    IERC20 public MSQ;
    IERC20 public MSQP;
    MSQLiquidityPool public liquidityPool;
    address public admin;

    constructor(IERC20 _MSQ, IERC20 _MSQP, MSQLiquidityPool _liquidityPool) {
        MSQ = _MSQ;
        MSQP = _MSQP;
        liquidityPool = _liquidityPool;
        admin = msg.sender;
    }

    function swapMSQToMSQP(uint256 amount) external {
        require(amount > 0, "Amount should be greater than 0");
        MSQ.safeTransferFrom(msg.sender, address(this), amount);
        liquidityPool.transferMSQP(admin, msg.sender, amount);
    }

    function swapMSQPToMSQ(uint256 amount) external {
        require(amount > 0, "Amount should be greater than 0");
        MSQP.safeTransferFrom(msg.sender, address(this), amount);
        liquidityPool.transferMSQ(admin, msg.sender, amount);
    }
}

