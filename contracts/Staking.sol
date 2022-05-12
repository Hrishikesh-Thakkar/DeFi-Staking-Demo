//stake: Users lock tocken into the smart contract
//withdraw: unlock tokens and pull out of the contract
//claimReward: Users get their reward (What's good rewards mechanism and formula)

// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Staking__TransferFailed();
error Staking__NeedsMoreThanZero();
contract Staking {
    //For a specific token
    IERC20 public s_stakingToken;
    IERC20 public s_rewardsToken;
    mapping(address => uint256) public s_balances;
    mapping(address => uint256) public s_userRewardPerTokenPaid;
    mapping(address => uint256) public s_rewards;
    
    uint256 public s_totalSupply = 0;
    uint256 public s_rewardPerTokenStored;
    uint256 public s_lastUpdateTime;
    uint256 public constant REWARD_RATE = 100;

    modifier updateReward(address account) {
        // HOW MUCH reward per token
        // last timestamp (get the time period)
        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[account] = earned(account);
        s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
        _;
    }

    modifier moreThanZero(uint256 amount) {
        if(amount == 0){
            revert Staking__NeedsMoreThanZero();
        }
        _;
    }
    constructor(address stakingToken, address rewardsToken){
        s_stakingToken = IERC20(stakingToken);
        s_rewardsToken = IERC20(rewardsToken);
    }

    function earned(address account) public view returns (uint256) {
        uint256 currentBalance = s_balances[account];
        uint256 amountPaid = s_userRewardPerTokenPaid[account];
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 pastRewards = s_rewards[account];
        uint256 _earned = ((currentBalance * (currentRewardPerToken - amountPaid))/1e18)+pastRewards;
        return _earned;
    }

    function rewardPerToken() public view returns(uint256) {
        if(s_totalSupply == 0){
            return s_rewardPerTokenStored;
        }
        return s_rewardPerTokenStored + (((block.timestamp - s_lastUpdateTime)*REWARD_RATE*1e18)/s_totalSupply);
    }
    //probably needs to payable
    function stake(uint256 amount) external updateReward(msg.sender) moreThanZero(amount) {
        //keep track of how much each user stakes
        //keep track of how much token we have in total
        //transfer the tokens to this contract 
        s_balances[msg.sender] = s_balances[msg.sender] + amount;
        s_totalSupply += amount;
        bool success = s_stakingToken.transferFrom(msg.sender,address(this),amount);
        // require(success, "Failed"); Gas inefficient
        if(!success) {
            revert Staking__TransferFailed();
        }
    }

    function withdraw(uint256 amount) external updateReward(msg.sender) moreThanZero(amount) {
        s_balances[msg.sender] = s_balances[msg.sender] - amount;
        s_totalSupply -= amount;
        bool success = s_stakingToken.transfer(msg.sender, amount);
        if(!success){
            revert Staking__TransferFailed();
        }
    }

    function claimReward() external updateReward(msg.sender) {
        //How much reward do they get?
        //contract emits X tokens per second and distributes them
        //Directly proportinate to the amount staked.
        uint256 reward = s_rewards[msg.sender];
        bool success = s_rewardsToken.transfer(msg.sender,reward);
        if(!success){
            revert Staking__TransferFailed();
        }
    }
}