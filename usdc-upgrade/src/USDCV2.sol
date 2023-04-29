// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Context } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { SafeMath } from "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";


contract Whitelist is Context {
    mapping(address => bool) internal whitelist;

    modifier onlyWhitelist {
        address sender = _msgSender();
        require(sender != address(0), "FiatToken: mint to the zero address");
        require(whitelist[sender]);
        _;
    }

    function isWhitelist(address _addr) external view returns(bool) {
        return whitelist[_addr];
    }

    function addWhitelist(address _addr) external onlyWhitelist returns(bool) {
        _addWhitelist(_addr);
        return true;
    }

    function revokeWhitelist(address _addr) external onlyWhitelist returns(bool) {
        _revokeWhitelist(_addr);
        return true;
    }

     function _addWhitelist(address _addr) internal {
        whitelist[_addr] = true;
    }

    function _revokeWhitelist(address _addr) internal  {
        whitelist[_addr] = false;
    } 
}

contract USDCV2 is Whitelist {
    using SafeMath for uint256;

    uint totalSupply_;
    mapping(address=>uint) balances;
    bool public initializedV2 = false;

    function initializeV2() external {
        require(initializedV2 == false, "initilized");
        initializedV2 = true;
        _addWhitelist(msg.sender);
    }

    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function mintAsWhitelist(uint256 _amount) external onlyWhitelist returns(bool) {
        require(_amount > 0, "FiatToken: mint amount not greater than 0");
        address sender = _msgSender();

        totalSupply_ = totalSupply_.add(_amount);
        balances[sender] = balances[sender].add(_amount);

        emit Mint(sender, sender, _amount);
        emit Transfer(address(0), sender, _amount);
        return true;
    }

    function balanceOf(address owner) external view returns(uint){
        return balances[owner];
    }

    function transfer(address to, uint256 value) external onlyWhitelist returns (bool) {
        require(value > 0, "FiatToken: transfer amount not greater than 0");
        _transfer(_msgSender(), to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        balances[from] = fromBalance - amount;
        balances[to] += amount;

        emit Transfer(from, to, amount);
    }
}
