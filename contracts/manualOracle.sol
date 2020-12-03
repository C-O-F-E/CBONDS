pragma solidity ^0.6.0;

import "./openzeppelin/math/SafeMath.sol";
import "./IOracle.sol";
import "./openzeppelin/access/Ownable.sol";

contract MOracle is Oracle,Ownable {
  mapping(address => uint) public override liquidityValues;
  uint public override syncValue=0;
  constructor() public Ownable(){

  }
  function setValue(address t,uint val) public onlyOwner{
    liquidityValues[t]=val;
  }
  function setMultipleValues(address[] memory tokens,uint[] memory vals) public onlyOwner{
    require(tokens.length==vals.length,"array lengths do not match");
    for(uint i=0;i<tokens.length;i++){
      liquidityValues[tokens[i]]=vals[i];
    }
  }
  function setSyncValue(uint value) public onlyOwner{
    syncValue=value;
  }
}
