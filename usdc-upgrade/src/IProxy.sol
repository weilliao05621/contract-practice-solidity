// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IProxy {
    function changeAdmin(address newAdmin) external;
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes memory data) payable external;
    function implementation() external view returns(address);
    function admin() external view returns(address);
}