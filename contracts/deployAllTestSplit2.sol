pragma solidity ^0.6.6;


import "./openzeppelin/token/ERC20/IERC20.sol";
import "./openzeppelin/math/SafeMath.sol";
import "./Sync.sol";
import "./fairreleaseschedule.sol";
import "./CBOND.sol";
import "./IOracle.sol";
import "./priceOracle.sol";
import "./openzeppelin/token/ERC20/ERC20.sol";
import "./manualOracle.sol";
import "./testToken.sol";

/*
contract ISync(){
  function setMintAccess(address account, bool canMint) public;
  function transferOwnership(address newOwner) public;
}
*/
interface IDeployAll1{
  function handoverSync() external returns(address);
  function o() external view returns(address);
  function s() external view returns(address);
  function l() external view returns(address);
}
contract DeployAll2 {
  using SafeMath for uint;

  IDeployAll1 d;
  Sync public s;
  CBOND public c;
  constructor(IDeployAll1 dep1) public{
    d=dep1;
    s= Sync(d.handoverSync());
    c= new CBOND(Oracle(d.o()),s);
    c.setLiquidityTokenAccepted(d.l(),true);
    s.setMintAccess(address(c),true);
    s.transferOwnership(msg.sender);
    c.transferOwnership(msg.sender);
  }
}
