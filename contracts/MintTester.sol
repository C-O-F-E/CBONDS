pragma solidity ^0.6.0;

import "./Sync.sol";

contract MintTester{
  Sync public syncContract;
  constructor(Sync s) public{
    syncContract=s;
  }
  function testMint(uint amount) public{
    syncContract._mint(address(this),amount);
  }
}
