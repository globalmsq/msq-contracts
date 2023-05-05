pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MSQLiquidityPool {
    using SafeERC20 for IERC20;

    IERC20 public MSQ;
    IERC20 public MSQX;
    address public admin;

    uint256 public feeRate = 25; // Fee rate in basis points (0.25%)
    uint256 constant BASIS_POINTS = 10000;

    mapping(address => uint256) public MSQDeposits;
    mapping(address => uint256) public MSQXDeposits;

    event LiquidityAdded(address indexed provider, uint256 msqAmount, uint256 msqxAmount);
    event LiquidityRemoved(address indexed provider, uint256 msqAmount, uint256 msqxAmount);

    constructor(IERC20 _MSQ, IERC20 _MSQX) {
        MSQ = _MSQ;
        MSQX = _MSQX;
        admin = msg.sender;
    }

    function addLiquidity(uint256 msqAmount, uint256 msqxAmount) external {
        require(msqAmount > 0 && msqxAmount > 0, "Amounts should be greater than 0");
        MSQ.safeTransferFrom(msg.sender, address(this), msqAmount);
        MSQX.safeTransferFrom(msg.sender, address(this), msqxAmount);
        MSQDeposits[msg.sender] += msqAmount;
        MSQXDeposits[msg.sender] += msqxAmount;
        emit LiquidityAdded(msg.sender, msqAmount, msqxAmount);
    }

    function removeLiquidity(uint256 msqAmount, uint256 msqxAmount) external {
        require(msqAmount > 0 && msqxAmount > 0, "Amounts should be greater than 0");
        require(MSQDeposits[msg.sender] >= msqAmount && MSQXDeposits[msg.sender] >= msqxAmount, "Insufficient liquidity");
        MSQ.safeTransfer(msg.sender, msqAmount);
        MSQX.safeTransfer(msg.sender, msqxAmount);
        MSQDeposits[msg.sender] -= msqAmount;
        MSQXDeposits[msg.sender] -= msqxAmount;
        emit LiquidityRemoved(msg.sender, msqAmount, msqxAmount);
    }

    function transferMSQ(address from, address to, uint256 amount) external {
        require(msg.sender == from || msg.sender == admin, "Unauthorized");
        require(MSQ.balanceOf(address(this)) >= amount, "Insufficient MSQ balance in the pool");

        uint256 fee = (amount * feeRate) / BASIS_POINTS;
        uint256 amountAfterFee = amount - fee;

        MSQ.safeTransfer(to, amountAfterFee);
        if (fee > 0) {
            MSQ.safeTransfer(admin, fee);
        }
    }

    function transferMSQP(address from, address to, uint256 amount) external {
        require(msg.sender == from || msg.sender == admin, "Unauthorized");
        require(MSQP.balanceOf(address(this)) >= amount, "Insufficient MSQP balance in the pool");

        uint256 fee = (amount * feeRate) / BASIS_POINTS;
        uint256 amountAfterFee = amount - fee;

        MSQP.safeTransfer(to, amountAfterFee);
         if (fee > 0) {
            MSQ.safeTransfer(admin, fee);
        }
    }
}
