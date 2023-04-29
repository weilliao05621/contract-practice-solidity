// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/USDCV2.sol";
import "../src/IProxy.sol";

contract USDCV2Test is Test {
    // Basic info of USDC
    address constant USDC_PROXY_CONTRACT = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDC_LOGIC_CONTRACT = 0xa2327a938Febf5FEC13baCFb16Ae10EcBc4cbDCF;
    address constant USDC_ADMIN = 0x807a96288A1A408dBC13DE2b1d087d10356395d2;
    address constant MASTER_MINTER = 0xE982615d461DD5cD06575BbeA87624fda4e3de17;

    // Fork network info
    string constant MAINNET_RPC_URL = "https://mainnet.infura.io/v3/ee11e79fa3d94cac84f2325726a61ba0";
    uint constant BLOCK_NUMBER = 17_150_125;

    uint forkId =  vm.createFork(MAINNET_RPC_URL, BLOCK_NUMBER);

    // users
    address v2Owner;
    address user1;

    // contracts
    USDCV2 usdcV2;
    USDCV2 proxyUSDCV2;
    address newImplementation;

    // balances
    uint constant INIT_BALANCES = 10000 ether;
    uint constant MINT_AMOUNT = 1 ether;

    function upgradeToV2() public {
        vm.startPrank(USDC_ADMIN);
        IProxy(USDC_PROXY_CONTRACT).upgradeTo(address(usdcV2));
        proxyUSDCV2 = USDCV2(USDC_PROXY_CONTRACT);
        vm.stopPrank();
    }

    function setUp() public {
        // Fork Id
        forkId = vm.createFork(MAINNET_RPC_URL, BLOCK_NUMBER);
        vm.selectFork(forkId);

        // Create users
        v2Owner = makeAddr("AWS");
        user1 = makeAddr("Alice");

        // Deploy v2
        vm.prank(v2Owner);
        usdcV2 = new USDCV2();
        newImplementation = address(usdcV2);
    }

    function test_SelectFork() public {
        assertEq(vm.activeFork(), forkId, "forkId");
    }

    function test_UpgradeTo() public {
        // pretend to be the owner
        vm.startPrank(USDC_ADMIN);
        address implementation = IProxy(USDC_PROXY_CONTRACT).implementation();
        assertEq(implementation, USDC_LOGIC_CONTRACT, "original logic contract address");
        
        // use interface for better callnig
        IProxy(USDC_PROXY_CONTRACT).upgradeTo(newImplementation);
        implementation = IProxy(USDC_PROXY_CONTRACT).implementation();
        assertEq(implementation, newImplementation, "new logic contract address");

        vm.stopPrank();
    }

    function test_addWhitelst_Initialize() public {
        upgradeToV2();

        vm.startPrank(v2Owner);
        proxyUSDCV2.initializeV2();
        bool initializedV2 = proxyUSDCV2.initializedV2();
        assertTrue(initializedV2);
        bool isWhitelist = proxyUSDCV2.isWhitelist(v2Owner);
        assertTrue(isWhitelist);
        vm.stopPrank();
    }

    function test_addWhitelst_AddUser1() public {
        upgradeToV2();

        vm.startPrank(v2Owner);
        proxyUSDCV2.initializeV2();
        proxyUSDCV2.addWhitelist(user1);
        vm.stopPrank();

        bool isWhitelist = proxyUSDCV2.isWhitelist(user1);
        assertTrue(isWhitelist);
    }

    function test_mintAsWhitelist_OwnerMint() public {
        upgradeToV2();

        uint balance = proxyUSDCV2.balanceOf(v2Owner);
        assertEq(balance, 0, "owner balance 0");

        vm.startPrank(v2Owner);
        proxyUSDCV2.initializeV2();
        proxyUSDCV2.mintAsWhitelist(MINT_AMOUNT);
        vm.stopPrank();

        balance = proxyUSDCV2.balanceOf(v2Owner);
        assertEq(balance, MINT_AMOUNT,"owner balance 1 ether");
    }

    function test_mintAsWhitelist_User1Mint() public {
        upgradeToV2();

        uint balance = proxyUSDCV2.balanceOf(user1);
        assertEq(balance, 0, "user1 balance 0");

        vm.startPrank(v2Owner);
        proxyUSDCV2.initializeV2();
        proxyUSDCV2.addWhitelist(user1);
        bool isWhiteList = proxyUSDCV2.isWhitelist(user1);
        assertTrue(isWhiteList,"user1 is whitelist");
        vm.stopPrank();

        vm.startPrank(user1);
        proxyUSDCV2.mintAsWhitelist(MINT_AMOUNT);
        balance = proxyUSDCV2.balanceOf(user1);
        assertEq(balance, MINT_AMOUNT,"user1 balance 1 ether");
        vm.stopPrank();
    }

    function test_transfer_AsWhitelist() public {
        upgradeToV2();
        
        vm.startPrank(v2Owner);
        proxyUSDCV2.initializeV2();
        proxyUSDCV2.addWhitelist(user1);
        proxyUSDCV2.mintAsWhitelist(MINT_AMOUNT);
        vm.stopPrank();

        vm.startPrank(user1);
        proxyUSDCV2.mintAsWhitelist(MINT_AMOUNT);
        proxyUSDCV2.transfer(v2Owner, MINT_AMOUNT);
        uint balanceUser1 = proxyUSDCV2.balanceOf(user1);
        uint balanceOwner = proxyUSDCV2.balanceOf(v2Owner);

        assertEq(balanceUser1,0,"user1 balance 0");
        assertEq(MINT_AMOUNT * 2, 2 ether);
        assertEq(balanceOwner, MINT_AMOUNT * 2,"owner balance 2 ether");
        vm.stopPrank();
    }

    function testFail_transfer_User1NotWhitelist() public {
        upgradeToV2();
        
        vm.startPrank(v2Owner);
        proxyUSDCV2.initializeV2();
        proxyUSDCV2.mintAsWhitelist(MINT_AMOUNT);
        proxyUSDCV2.transfer(user1, MINT_AMOUNT);
        vm.stopPrank();

        uint balanceUser1 = proxyUSDCV2.balanceOf(user1);
        assertEq(balanceUser1, MINT_AMOUNT,"user1 balance 1 ether");

        vm.prank(user1);
        proxyUSDCV2.transfer(v2Owner, MINT_AMOUNT);
    }
}
