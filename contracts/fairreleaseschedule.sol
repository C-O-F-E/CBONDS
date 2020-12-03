pragma solidity ^0.6.0;


import "./openzeppelin/token/ERC20/IERC20.sol";
import "./openzeppelin/math/SafeMath.sol";
import "./Sync.sol";
import "./openzeppelin/access/Ownable.sol";

contract FRS is Ownable {
  using SafeMath for uint256;

  //Constant and pseudo constant values
  uint256 constant public INITIAL_DAILY_REWARD = 5000000 * (10**18); //Base daily reward amount. A reduction is applied to this which increases over time to compute the actual daily reward.
  uint256 constant public TIME_INCREMENT=1 days;//Amount of time between each Sync release.

  //Variables related to the day index
  mapping(uint256 => mapping(address => uint256)) public amountEntered; //Amount of Eth entered by day index, by user.
  mapping(uint256 => uint256) public totalDailyContribution; //Total amount of Eth entered for the given day index.
  mapping(uint256 => uint256) public totalDailyRewards; //Total amount of tokens to be distributed for the given day index.
  mapping(uint256 => mapping(address => uint256)) public totalDailyPayouts; //Amount paid out to given user address for each given day index.
  uint256 public currentDayIndex=0;//Current day index. Represents the number of Sync releases which have occurred. Will also represent the number of days which have passed since the contract started, minus the number of days which have been skipped due to inactivity.

  //Other mappings
  mapping(uint256 => address payable) public maintainers;//A list of maintainer addresses, which are given a portion of Sync rewards.

  //Timing variables
  uint256 public nextDayAt=0;//The timestamp at which the current release is finalized and the next one begins.
  uint256 public firstEntryTime=0;//The time of the very first interaction with the contract, is the starting point for the first day.

  //External contracts
  Sync public syncToken;//The Sync token contract. The FRS contract mints these tokens to reward to users daily.

  constructor(address token) public Ownable(){//(address tokenAddr,address fundAddr) public{
    syncToken=Sync(token);
    totalDailyRewards[currentDayIndex]=INITIAL_DAILY_REWARD;
    maintainers[0]=0xf8F1e9335481E22Ec634d73B511E1CF5550C8194;
    maintainers[1]=0x2fFD215E32bF25366172a5470FCEA3182C6c718F;
    maintainers[2]=0xaF35f3685C92b83E8e64880441FA39FE2B6Fcf48;
    maintainers[3]=0x5ed7D8e2089B2B0e15439735B937CeC5F0ae811B;
    maintainers[4]=0x73b8c96A1131C19B6A0Dc972099eE5E2B328f66B;
    maintainers[5]=0x8AB0b38B5331ADAe0EDfB713c714521964C5bCCC;
  }

  /*
    Transfers the appropriate amount of Eth and Sync to the maintainers; to be called at the conclusion of each release.
  */
  function distributeToMaintainers(uint256 syncAmount) private{
    if(syncAmount>0){
      uint256 syncAmt1=syncAmount.mul(5).div(100);
      uint256 syncAmt2=syncAmount.mul(283).div(1000);//28.3%, half of the remainder after 5*3%
      syncToken._mint(maintainers[0],syncAmt1);
      syncToken._mint(maintainers[1],syncAmt1);
      syncToken._mint(maintainers[2],syncAmt1);

      syncToken._mint(maintainers[3],syncAmt2);
      syncToken._mint(maintainers[4],syncAmt2);
      syncToken._mint(maintainers[5],syncAmt2);
    }
    uint256 ethAmount=address(this).balance;
    if(ethAmount>0){
      uint256 ethAmt1=ethAmount.mul(5).div(100);//5%
      uint256 ethAmt2=ethAmount.mul(283).div(1000);//28.3%

      //send used rather than transfer to remove possibility of denial of service by refusing transfer
      maintainers[0].send(ethAmt1);
      maintainers[1].send(ethAmt1);
      maintainers[2].send(ethAmt1);

      maintainers[3].send(ethAmt2);
      maintainers[4].send(ethAmt2);
      maintainers[5].send(ethAmt2);
    }
  }

  /*
    Function for entering Eth into the release for the current day.
  */
  function enter() external payable{
    require(msg.value>0,"payment required");
    //Concludes the previous contest if needed
    updateDay();
    //Record user contribution
    amountEntered[currentDayIndex][msg.sender]+=msg.value;
    totalDailyContribution[currentDayIndex]+=msg.value;
  }

  /*
    If the current release has concluded, perform all operations necessary to progress to the next release.
  */
  function updateDay() private{
    //starts timer if first transaction
    if(nextDayAt==0){
      //The first transaction to this contract determines which time each day the release will conclude.
      nextDayAt=block.timestamp.add(TIME_INCREMENT);
      firstEntryTime=block.timestamp;
    }
    if(block.timestamp>=nextDayAt){
      distributeToMaintainers(totalDailyRewards[currentDayIndex]);
      //Determine the minimum number of days to add so that the next release ends at a future date. This is done so that every release will end at the same time of day.
      uint256 daysToAdd=1+(block.timestamp-nextDayAt)/TIME_INCREMENT;
      nextDayAt+=TIME_INCREMENT*daysToAdd;
      currentDayIndex+=1;
      //for every month until the 13th, rewards are cut in half.
      uint256 numMonths=block.timestamp.sub(firstEntryTime).div(30 days);
      if(numMonths>12){
        totalDailyRewards[currentDayIndex]=0;
      }
      else{
        totalDailyRewards[currentDayIndex]=INITIAL_DAILY_REWARD.div(2**numMonths);
      }
    }
  }

  /*
    Function for users to withdraw rewards for multiple days.
  */
  function withdrawForMultipleDays(uint256[] calldata dayList) external{
    //Concludes the previous contest if needed
    updateDay();
    uint256 cumulativeAmountWon=0;
    uint256 amountWon=0;
    for(uint256 i=0;i<dayList.length;i++){
      amountWon=_withdrawForDay(dayList[i],currentDayIndex,msg.sender);
      cumulativeAmountWon+=amountWon;
      totalDailyPayouts[dayList[i]][msg.sender]+=amountWon;//record how much was paid
    }
    syncToken._mint(msg.sender,cumulativeAmountWon);
  }

  /*
    Function for users to withdraw rewards for a single day.
  */
  function withdrawForDay(uint256 day) external{
    //Concludes the previous contest if needed
    updateDay();
    uint256 amountWon=_withdrawForDay(day,currentDayIndex,msg.sender);
    totalDailyPayouts[day][msg.sender]+=amountWon;//record how much was paid
    syncToken._mint(msg.sender,amountWon);
  }

  /*
    Returns amount that should be withdrawn for the given day.
  */
  function _withdrawForDay(uint256 day,uint256 dayCursor,address user) public view returns(uint256){
    if(day>=dayCursor){//you can only withdraw funds for previous days
      return 0;
    }
    //Amount owed is proportional to the amount entered by the user vs the total amount of Eth entered.
    uint256 amountWon=totalDailyRewards[day].mul(amountEntered[day][user]).div(totalDailyContribution[day]);
    uint256 amountPaid=totalDailyPayouts[day][user];
    return amountWon.sub(amountPaid);
  }

  /*
    The following functions are only used externally, intended to assist with frontend calculations, not meant to be called onchain.
  */

  /*
    Returns the current day index as it will be after updateDay is called.
  */
  function currentDayIndexActual() external view returns(uint256){
    if(block.timestamp>=nextDayAt){
      return currentDayIndex+1;
    }
    else{
      return currentDayIndex;
    }
  }

  /*
    Returns the amount of Sync the user will get if withdrawing for the provided day indices.
  */
  function getPayoutForMultipleDays(uint256[] calldata dayList,uint256 dayCursor,address addr) external view returns(uint256){
    uint256 cumulativeAmountWon=0;
    for(uint256 i=0;i<dayList.length;i++){
      cumulativeAmountWon+=_withdrawForDay(dayList[i],dayCursor,addr);
    }
    return cumulativeAmountWon;
  }

  /*
    Returns a list of day indexes for which the given user has available rewards.
  */
  function getDaysWithFunds(uint256 start,uint256 end,address user) external view returns(uint256[] memory){
    uint256 numDays=0;
    for(uint256 i=start;i<min(currentDayIndex+1,end);i++){
      if(amountEntered[i][user]>0){
        numDays+=1;
      }
    }
    uint256[] memory dwf=new uint256[](numDays);
    uint256 cursor=0;
    for(uint256 i=start;i<min(currentDayIndex+1,end);i++){
      if(amountEntered[i][user]>0){
        dwf[cursor]=i;
        cursor+=1;
      }
    }
    return dwf;
  }

  /*
    Utility function, returns the smaller number.
  */
  function min(uint256 n1,uint256 n2) internal pure returns(uint256){
    if(n1<n2){
      return n1;
    }
    else{
      return n2;
    }
  }
}
