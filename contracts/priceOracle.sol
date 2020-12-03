pragma solidity ^0.6.0;

import './uniswap/UniswapV2Library.sol';
import "./openzeppelin/math/SafeMath.sol";
import "./IOracle.sol";

interface IDecimals{
  function decimals() external view returns (uint256);
}
contract PriceChecker is Oracle {
  using SafeMath for uint256;

  address public factory;
  address public syncAddr;
  address public weth;
  uint256 public constant ONE_TOKEN = 10 ** 18;
  uint256 public constant MAGNITUDE = 10 ** 16;
  constructor(address snc,address f,address we) public{
    factory=f;
    syncAddr=snc;
    weth=we;
  }

  /*
    Gets the current price of Sync in Eth.
  */
  function syncValue() external view override returns(uint256){
    return checkPrice(syncAddr);
  }

  /*
    Gets the current value of a given Uniswap V2 liquidity token, by returning twice the Eth value of the non-weth tokens contained in a single liquidity token.
  */
  function liquidityValues(address liqToken) external view override returns(uint256){
    IUniswapV2Pair _pair = IUniswapV2Pair(liqToken);
    (uint112 r0,uint112 r1,) = _pair.getReserves();
    //Ratio representing 1 / total supply of liquidity tokens.
    uint256 ratio = MAGNITUDE.mul(ONE_TOKEN).div(_pair.totalSupply());
    if(_pair.token0()==weth){
      //Amount of Eth the non-eth liquidity reserve is worth
      uint256 ethForReserve = getPricePair(r1,_pair.token1(),_pair.token1(),weth);
      //Return twice the amount of Eth the non-eth tokens contained in 1 liquidity token would be worth.
      return ethForReserve.mul(ratio).div(MAGNITUDE).mul(2);
    }
    else{
      uint256 ethForReserve = getPricePair(r0,_pair.token0(),_pair.token0(),weth);
      return ethForReserve.mul(ratio).div(MAGNITUDE).mul(2);
    }
  }
  function debugInfo(address liqToken) external view returns(uint112 r0,uint112 r1,address token0,address token1,uint256 pairtotalsupply){
    IUniswapV2Pair _pair = IUniswapV2Pair(liqToken);
    (r0,r1,) = _pair.getReserves();
    token0=_pair.token0();
    token1=_pair.token1();
    pairtotalsupply=_pair.totalSupply();
  }
  function debugRatio(address liqToken) external view returns(uint256,uint256){
    IUniswapV2Pair _pair = IUniswapV2Pair(liqToken);
    (uint112 r0,uint112 r1,) = _pair.getReserves();
    return (
      MAGNITUDE.mul(ONE_TOKEN).div(_pair.totalSupply()),
      MAGNITUDE);
  }
  function debugMagnitude(address liqToken) external view returns(uint){
      IUniswapV2Pair _pair = IUniswapV2Pair(liqToken);
      (uint112 r0,uint112 r1,) = _pair.getReserves();
      uint test=MAGNITUDE.mul(ONE_TOKEN).div(_pair.totalSupply());
      return MAGNITUDE;
    }
  /*
    Returns the value of the given amount of the given trade token for the given pair.
  */
  function getPricePair(uint256 amountIn,address tradeToken,address tokenA,address tokenB) public view returns(uint256){
    IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, tokenA, tokenB));
    (uint112 r0,uint112 r1,) = _pair.getReserves();
    if(_pair.token0()==tradeToken){
      return UniswapV2Library.quote(amountIn,uint256(r0),uint256(r1));
    }
    else{
      return UniswapV2Library.quote(amountIn,uint256(r1),uint256(r0));
    }

  }

  /*
    Returns the price of a fixed quantity of the given token (1 token if it is 18 decimals).
    Token should be 18 decimals or less.
    Price returned is in terms of Eth.
  */
  function checkPrice(address tradeToken) public view returns(uint256){
    return getPricePair(ONE_TOKEN,tradeToken,tradeToken,weth);
  }
}
