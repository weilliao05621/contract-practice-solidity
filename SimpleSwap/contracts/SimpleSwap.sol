// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20, IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { Math } from "./libs/Math.sol";
import { SafeMath } from "./libs/SafeMath.sol";

contract ZeroAddress {}

contract SimpleSwap is ISimpleSwap, ERC20("Uniswap V2", "UNI-V2") {
    using Math for uint256;
    using SafeMath for uint256;
    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;

    bytes4 private constant _SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    address private _token0;
    address private _token1;
    address private immutable _ZERO_ADDRESS; // ERC20 不允許 mint 給 zero address

    uint256 private _reserveA;
    uint256 private _reserveB;

    uint256 public kLast;

    constructor(address tokenA_, address tokenB_) {
        require(tokenA_.code.length != 0, "SimpleSwap: TOKENA_IS_NOT_CONTRACT");
        require(tokenB_.code.length != 0, "SimpleSwap: TOKENB_IS_NOT_CONTRACT");
        require(tokenA_ != tokenB_, "SimpleSwap: TOKENA_TOKENB_IDENTICAL_ADDRESS");
        _ZERO_ADDRESS = address(new ZeroAddress());
        _token0 = tokenA_ < tokenB_ ? tokenA_ : tokenB_;
        _token1 = tokenA_ > tokenB_ ? tokenA_ : tokenB_;
    }

    receive() external payable {}

    // 拿走別人的代幣，給它 LP 代幣
    function addLiquidity(
        uint256 amountAIn,
        uint256 amountBIn
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        (uint256 _reserve0, uint256 _reserve1) = getReserves(); // gas savings
        address token0 = _token0; // gas savings
        address token1 = _token1; // gas savings

        _safeTransferFrom(token0, amountAIn);
        _safeTransferFrom(token1, amountBIn);

        uint256 balance0 = _getTokenBalance(token0);
        uint256 balance1 = _getTokenBalance(token1);

        amountA = balance0 - _reserve0;
        amountB = balance1 - _reserve1;

        uint256 _totalSupply = totalSupply(); // gas savings

        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amountA.mul(amountB)).sub(MINIMUM_LIQUIDITY);
            _mint(_ZERO_ADDRESS, MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amountA.mul(_totalSupply) / _reserve0, amountB.mul(_totalSupply) / _reserve1);
        }

        require(liquidity > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(msg.sender, liquidity);

        _update(balance0, balance1);

        emit AddLiquidity(msg.sender, amountAIn, amountBIn, liquidity);
    }

    function removeLiquidity(uint256 liquidity) external returns (uint256 amountA, uint256 amountB) {
        address token0 = _token0; // gas savings
        address token1 = _token1; // gas savings

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 _totalSupply = totalSupply();

        amountA = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amountB = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution

        require(amountA > 0 && amountB > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);

        _safeTransfer(token0, msg.sender, amountA);
        _safeTransfer(token1, msg.sender, amountB);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        _update(balance0, balance1);

        emit Transfer(address(this), address(0), liquidity);
        // emit RemoveLiquidity(msg.sender, amountA, amountB, liquidity);
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256 amountOut) {}

    function getTokenA() external view returns (address tokenA) {
        tokenA = _token0;
    }

    function getTokenB() external view returns (address tokenB) {
        tokenB = _token1;
    }

    function getReserves() public view returns (uint256 reserveA, uint256 reserveB) {
        reserveA = _reserveA;
        reserveB = _reserveB;
    }

    /*
        一定要使用 call 來讓 msg.sender 變成合約，不然無法以合約身分調用 ERC20
    */
    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(_SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "UniswapV2: TRANSFER_FAILED");
    }

    function _safeTransferFrom(address token, uint256 amountAIn) private {
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amountAIn);
        require(success, "UniswapV2: TRANSFER_FROM_FAILED");
    }

    function _getTokenBalance(address token) private view returns (uint256 balance) {
        balance = IERC20(token).balanceOf(address(this));
    }

    function _update(uint256 balance0, uint256 balance1) private {
        _reserveA = balance0;
        _reserveB = balance1;
    }
}
