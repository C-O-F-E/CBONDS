pragma solidity ^0.6.6;


import "./openzeppelin/token/ERC20/IERC20.sol";
import "./openzeppelin/math/SafeMath.sol";
import "./Sync.sol";
import "./fairreleaseschedule.sol";
import "./CBOND.sol";
import "./IOracle.sol";
import "./priceOracle.sol";
import "./openzeppelin/token/ERC20/ERC20.sol";
import "./openzeppelin/access/Ownable.sol";
import "./manualOracle.sol";


contract DeployAllLive {
  using SafeMath for uint;

  FRS public f;
  Oracle public o;
  CBOND public c;
  constructor(Sync s,address uniswapfactory,address weth) public{
    f= new FRS(address(s));
    o= Oracle(new PriceChecker(address(s),uniswapfactory,weth));
    c= new CBOND(o,s);
    f.transferOwnership(msg.sender);
    Ownable(address(o)).transferOwnership(msg.sender);
    c.transferOwnership(msg.sender);
  }
}
