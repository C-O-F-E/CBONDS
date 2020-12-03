pragma solidity ^0.6.0;

import "./openzeppelin/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
  constructor(string memory name,string memory symbol,uint startingSupply) public ERC20(name,symbol){
    _mint(msg.sender,startingSupply);
  }
}
