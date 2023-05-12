pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PolygonStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;
    uint256 public rewardRate;
    uint256 public totalStaked;
    mapping(address => uint256) public userStaked;
    mapping(address => uint256) public userRewards;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(IERC20 _stakingToken, uint256 _rewardRate) {
        stakingToken = _stakingToken;
        rewardRate = _rewardRate;
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than zero");

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        userStaked[msg.sender] = userStaked[msg.sender].add(_amount);
        totalStaked = totalStaked.add(_amount);

        emit Staked(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external {
        require(userStaked[msg.sender] >= _amount, "Not enough tokens staked");

        stakingToken.safeTransfer(msg.sender, _amount);
        userStaked[msg.sender] = userStaked[msg.sender].sub(_amount);
        totalStaked = totalStaked.sub(_amount);

        emit Unstaked(msg.sender, _amount);
    }

    function claimReward() external {
        uint256 reward = userStaked[msg.sender].mul(rewardRate).div(1e18);
        require(reward > 0, "No rewards available");

        stakingToken.safeTransfer(msg.sender, reward);
        userRewards[msg.sender] = userRewards[msg.sender].add(reward);

        emit RewardClaimed(msg.sender, reward);
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
    }

    function getUserStaked(address _user) external view returns (uint256) {
        return userStaked[_user];
    }

    function getUserRewards(address _user) external view returns (uint256) {
        return userRewards[_user];
    }

    function getRewardAmount(address _user) external view returns (uint256) {
        return userStaked[_user].mul(rewardRate).div(1e18);
    }
}

