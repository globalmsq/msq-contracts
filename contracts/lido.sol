pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@lidofinance/lido-dao/contracts/Lido.sol";



contract SuperSave {

  address public lidoAddress;
  address public tokenAddress;
  mapping(address => uint256) public stakedAmounts;
  mapping(address => bytes32) public redeemableReceipts;
  mapping(bytes32 => address) public redeemCodeToUser;

  event Staked(address indexed user, uint256 amount);
  event Unstaked(address indexed user, uint256 amount);
  event RedeemCodeGenerated(bytes32 redeemCode);
  event RedeemRedeemReceipt(bytes32 redeemCode);

  constructor(address _lidoAddress, address _tokenAddress) {
    lidoAddress = _lidoAddress;
    tokenAddress = _tokenAddress;
  }

  function generateRedeemCode() public returns (bytes32 redeemCode) {
    redeemCode = keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty));
    redeemCodeToUser[redeemCode] = msg.sender;
    emit RedeemCodeGenerated(redeemCode);
  }


  // Function to redeem redeem code
  function redeemRedeemCode(bytes32 redeemCode) public {
    // Check if the redeem code is valid
    require(redeemCodeToUser[redeemCode] == msg.sender);

    // Delete the redeem code from the mapping
    delete redeemCodeToUser[redeemCode];

    // Get the user's Lido account
    address lidoAccount = Lido(lidoAddress).getAccount(msg.sender);

    // Redeem the redeemable receipt for stETH
    Lido(lidoAddress).redeemRedeemReceipt(lidoAccount, redeemCode);

    // Emit the RedeemRedeemReceipt event
    emit RedeemRedeemReceipt(redeemCode);
  }

  // Function to stake ETH
  function stake(uint256 amount) public {
    // Check if the user has enough ETH
    require(amount <= address(this).balance);

    // Get the user's Lido account
    address lidoAccount = Lido(lidoAddress).getAccount(msg.sender);

    // Deposit ETH into the Lido account
    Lido(lidoAddress).deposit(lidoAccount, amount);

    // Update the user's staked amount
    stakedAmounts[msg.sender] += amount;

    // Get the redeemable receipt from the Lido protocol
    bytes32 redeemableReceipt = Lido(lidoAddress).getRedeemableReceipt(lidoAccount);

    // Store the redeemable receipt in the mapping
    redeemableReceipts[msg.sender] = redeemableReceipt;

    // Emit the Staked event
    emit Staked(msg.sender, amount);
  }

  
    
 function unstake(uint256 amount) public {
    // Check if the user has enough staked ETH
    require(stakedAmounts[msg.sender] >= amount);

    // Get the user's Lido account
    address lidoAccount = Lido(lidoAddress).getAccount(msg.sender);

    // Withdraw ETH from the Lido account
    Lido(lidoAddress).withdraw(lidoAccount, amount);

    // Update the user's staked amount
    stakedAmounts[msg.sender] -= amount;

    // Delete the redeemable receipt from the mapping
    delete redeemableReceipts[msg.sender];

    // Get the stETH token contract
    ERC20 token = ERC20(tokenAddress);

    // Burn the stETH from the user's account
    token.burn(msg.sender, amount);

    // Emit the Unstaked event
    emit Unstaked(msg.sender, amount);
  }
 }

