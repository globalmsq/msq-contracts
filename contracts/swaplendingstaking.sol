pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./AaveInterfaces.sol";
import "./QuickSwapInterfaces.sol";

contract SwapLendingStaking is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Aave contracts
    address public constant aaveLendingPoolAddressesProvider = 0xAddressHere;
    ILendingPoolAddressesProvider public lendingPoolAddressesProvider;
    ILendingPool public lendingPool;

    // QuickSwap contracts
    address public constant quickSwapRouterAddress = 0xAddressHere;
    IUniswapV2Router02 public quickSwapRouter;

    constructor() {
        lendingPoolAddressesProvider = ILendingPoolAddressesProvider(aaveLendingPoolAddressesProvider);
        lendingPool = ILendingPool(lendingPoolAddressesProvider.getLendingPool());
        quickSwapRouter = IUniswapV2Router02(quickSwapRouterAddress);
    }

    function swap(
        IERC20 _tokenA,
        IERC20 _tokenB,
        uint256 _tokenAIn,
        uint256 _tokenBOutMin,
        address _to,
        uint256 _deadline
    ) external {
        _tokenA.safeTransferFrom(msg.sender, address(this), _tokenAIn);
        _tokenA.safeApprove(address(quickSwapRouter), _tokenAIn);

        address[] memory path = new address[](2);
        path[0] = address(_tokenA);
        path[1] = address(_tokenB);

        quickSwapRouter.swapExactTokensForTokens(
            _tokenAIn,
            _tokenBOutMin,
            path,
            _to,
            _deadline
        );
    }

    function depositToAave(IERC20 _token, uint256 _amount) external {
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        _token.safeApprove(address(lendingPool), _amount);
        lendingPool.deposit(address(_token), _amount, msg.sender, 0);
    }

    function withdrawFromAave(IERC20 _token, uint256 _amount) external {
        lendingPool.withdraw(address(_token), _amount, msg.sender);
    }

     function addLiquidity(
        IERC20 _tokenA,
        IERC20 _tokenB,
        uint256 _tokenAAmount,
        uint256 _tokenBAmount,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    ) external {
        _tokenA.safeTransferFrom(msg.sender, address(this), _tokenAAmount);
        _tokenB.safeTransferFrom(msg.sender, address(this), _tokenBAmount);
        _tokenA.safeApprove(address(quickSwapRouter), _tokenAAmount);
        _tokenB.safeApprove(address(quickSwapRouter), _tokenBAmount);

        quickSwapRouter.addLiquidity(
            address(_tokenA),
            address(_tokenB),
            _tokenAAmount,
            _tokenBAmount,
            _amountAMin,
            _amountBMin,
            _to,
            _deadline
        );
    }

    function removeLiquidity(
        IERC20 _tokenA,
        IERC20 _tokenB,
        uint256 _liquidity,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    ) external {
        IERC20 lpToken = IERC20(quickSwapRouter.pairFor(address(_tokenA), address(_tokenB)));
        lpToken.safeTransferFrom(msg.sender, address(this), _liquidity);
        lpToken.safeApprove(address(quickSwapRouter), _liquidity);

        quickSwapRouter.removeLiquidity(
            address(_tokenA),
            address(_tokenB),
            _liquidity,
            _amountAMin,
            _amountBMin,
            _to,
            _deadline
        );
    } 
    
    
    function stakeLPTokens(
        IERC20 _lpToken,
        uint256 _amount
    ) external {
        _lpToken.safeTransferFrom(msg.sender, address(this), _amount);
        _lpToken.safeApprove(address(quickStake), _amount);
        quickStake.stake(msg.sender, address(_lpToken), _amount);
    }

    function unstakeLPTokens(
        IERC20 _lpToken,
        uint256 _amount
    ) external {
        quickStake.unstake(msg.sender, address(_lpToken), _amount);
        _lpToken.safeTransfer(msg.sender, _amount);
    }
}
