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

contract DeployAll {
  using SafeMath for uint;

  Sync public s;
  FRS public f;
  MOracle public o;
  CBOND public c;
  IERC20 public l;
  constructor() public{
    l=new TestToken("Liquidity Token Example","LIQT",100e18);
    s= new Sync(); //later replace this with using the existing token
    f= new FRS(address(s));
    o= new MOracle();//new PriceChecker(address(s),uniswapfactory,weth);
    MOracle(o).setValue(address(l),1000000000000000000);// token price 1 dollar
    MOracle(o).setSyncValue(500000000000000000);// token price 50 cents
    c= new CBOND(o,s);
    c.setLiquidityTokenAccepted(address(l),true);
    s.setMintAccess(address(c),true);
    s.setMintAccess(address(f),true);
    l.transfer(msg.sender,l.balanceOf(address(this)));
    s.transfer(msg.sender,s.balanceOf(address(this)));
    s.transferOwnership(msg.sender);
    f.transferOwnership(msg.sender);
    o.transferOwnership(msg.sender);
    c.transferOwnership(msg.sender);
  }
}
