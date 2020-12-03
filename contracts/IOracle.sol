pragma solidity ^0.6.0;

interface Oracle{
  function liquidityValues(address token) external view returns(uint);//returns usd value of token (consider usd an 18 decimal stablecoin), or 0 if not listed
  function syncValue() external view returns(uint);//returns usd value of SYNC
}
