// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "forge-std/Test.sol";

import {DemoErc721} from "../src/ERC721.sol";
import {DemoErc721a} from "../src/ERC721A.sol";

contract TestAllERC721 is Test {
    uint256 constant MINT_SIZE = 10;

    DemoErc721 erc721;
    DemoErc721a erc721a;

    address alice = makeAddr("Alice");
    address bob = makeAddr("Bob");
    address charlie = makeAddr("Charlie");

    function setUp() public virtual {
        erc721 = new DemoErc721();
        erc721a = new DemoErc721a();
    }
}

contract Mint is TestAllERC721 {
    function test_ERC721_mint() public {
        uint256 preTotalSupply = erc721.totalSupply();
        erc721.mint(alice, 1);
        uint256 postTotalSupply = erc721.totalSupply();
        uint256 balanceOfAlice = erc721.balanceOf(alice);

        assertTrue(postTotalSupply - preTotalSupply == 1);
        assertEq(balanceOfAlice, 1, "fail to mint 10 token for Alice");
    }

    function test_ERC721_Separate10Times() public {
        for (uint256 i = 0; i < MINT_SIZE; ) {
            erc721.mint(alice, 1);
            unchecked {
                ++i;
            }
        }
    }

    function test_ERC721_Batch10() public {
        uint256 preTotalSupply = erc721.totalSupply();
        erc721.mint(alice, MINT_SIZE);
        uint256 postTotalSupply = erc721.totalSupply();
        uint256 balanceOfAlice = erc721.balanceOf(alice);

        assertTrue(postTotalSupply - preTotalSupply == MINT_SIZE);
        assertEq(balanceOfAlice, MINT_SIZE, "fail to mint 10 token for Alice");
    }

    function test_ERC721A_mint() public {
        uint256 preTotalSupply = erc721a.totalSupply();
        erc721a.mint(alice, 1);
        uint256 postTotalSupply = erc721a.totalSupply();
        uint256 balanceOfAlice = erc721a.balanceOf(alice);

        assertTrue(postTotalSupply - preTotalSupply == 1);
        assertEq(balanceOfAlice, 1, "fail to mint 10 token for Alice");
    }

    function test_ERC721A_Separate10Times() public {
        for (uint256 i = 1; i < MINT_SIZE; ) {
            erc721a.mint(alice, 1);
            unchecked {
                ++i;
            }
        }
    }

    function test_ERC721A_Batch10() public {
        uint256 preTotalSupply = erc721a.totalSupply();
        erc721a.mint(alice, MINT_SIZE);
        uint256 postTotalSupply = erc721a.totalSupply();
        uint256 balanceOfAlice = erc721a.balanceOf(alice);

        assertTrue(postTotalSupply - preTotalSupply == MINT_SIZE);
        assertEq(balanceOfAlice, MINT_SIZE, "fail to mint 10 token for Alice");
    }
}

contract SafeTransferFrom is TestAllERC721 {
    function setUp() public override {
        super.setUp();

        erc721.mint(alice, MINT_SIZE);
        erc721a.mint(alice, MINT_SIZE);
    }

    function test_SetUpState() public {
        uint256 totalSupplyErc721 = erc721.totalSupply();
        uint256 totalSupplyErc721a = erc721a.totalSupply();
        uint256 erc721BalanceOfAlice = erc721.balanceOf(alice);
        uint256 erc721aBalanceOfAlice = erc721a.balanceOf(alice);
        assertTrue(totalSupplyErc721 == MINT_SIZE);
        assertTrue(totalSupplyErc721a == MINT_SIZE);
        assertEq(
            erc721BalanceOfAlice,
            MINT_SIZE,
            "fail to mint 10 token for Alice"
        );
        assertEq(
            erc721aBalanceOfAlice,
            MINT_SIZE,
            "fail to mint 10 token for Alice"
        );
    }

    function test_ERC721_Transfer10Token() public {
        vm.startPrank(alice);

        for (uint256 i = 0; i < MINT_SIZE; ) {
            erc721.safeTransferFrom(alice, bob, i);
            assertEq(erc721.ownerOf(i), bob);
            unchecked {
                ++i;
            }
        }

        assertEq(erc721.balanceOf(bob), MINT_SIZE);
        vm.stopPrank();
    }

    function test_ERC721_BehindTokenIdIsEOA() public {
        erc721.mint(bob, 1);
        assertEq(
            erc721.ownerOf(MINT_SIZE),
            bob,
            "Bob is not the owner of tokenId 10"
        );

        uint256 tokenIdToSend = 9;

        vm.startPrank(alice);
        erc721.safeTransferFrom(alice, charlie, tokenIdToSend);
        assertEq(erc721.ownerOf(tokenIdToSend), charlie);
    }

    function test_ERC721_BehindTokenIdIsNotEOA() public {
        uint256 tokenIdToSend = 5;

        vm.startPrank(alice);

        erc721.safeTransferFrom(alice, charlie, tokenIdToSend);
        assertEq(erc721.ownerOf(tokenIdToSend), charlie);
    }

    function test_ERC721A_Transfer10Token() public {
        vm.startPrank(alice);

        for (uint256 i = 0; i < MINT_SIZE; ) {
            erc721a.safeTransferFrom(alice, bob, i);
            assertEq(erc721a.ownerOf(i), bob);
            unchecked {
                ++i;
            }
        }

        assertEq(erc721a.balanceOf(bob), MINT_SIZE);
        vm.stopPrank();
    }

    function test_ERC721A_BehindTokenIdIsEOA() public {
        erc721a.mint(bob, 1);
        assertEq(
            erc721a.ownerOf(MINT_SIZE),
            bob,
            "Bob is not the owner of tokenId 10"
        );

        uint256 tokenIdToSend = 9;

        vm.startPrank(alice);
        erc721a.safeTransferFrom(alice, charlie, tokenIdToSend);
        assertEq(erc721a.ownerOf(tokenIdToSend), charlie);
    }

    function test_ERC721A_BehindTokenIdIsNotEOA() public {
        uint256 tokenIdToSend = 5;

        vm.startPrank(alice);

        erc721a.safeTransferFrom(alice, charlie, tokenIdToSend);
        assertEq(erc721a.ownerOf(tokenIdToSend), charlie);
    }
}

contract Approve is TestAllERC721 {
    function setUp() public override {
        super.setUp();

        erc721.mint(alice, MINT_SIZE);
        erc721a.mint(alice, MINT_SIZE);
    }

    function test_ERC721_Approve1Token() public {
        uint256 tokenId = 0;
        vm.prank(alice);
        erc721.approve(bob, tokenId);

        assertEq(
            erc721.getApproved(tokenId),
            bob,
            "Fail to approve ERC721 to Bob"
        );
    }

    function test_ERC721_ApprovalAllToken() public {
        vm.prank(alice);
        erc721.setApprovalForAll(bob, true);

        assertEq(erc721.isApprovedForAll(alice, bob), true);
    }

    function test_ERC721_ApproveLastToken() public {
        uint256 tokenId = 9;
        vm.prank(alice);
        erc721.approve(bob, tokenId);

        assertEq(
            erc721.getApproved(tokenId),
            bob,
            "Fail to approve ERC721 to Bob"
        );
    }

    function test_ERC721A_Approve1Token() public {
        uint256 tokenId = 0;
        vm.prank(alice);
        erc721a.approve(bob, tokenId);

        assertEq(
            erc721a.getApproved(tokenId),
            bob,
            "Fail to approve ERC721A to Bob"
        );
    }

    function test_ERC721A_ApprovalAllToken() public {
        vm.prank(alice);
        erc721a.setApprovalForAll(bob, true);

        assertEq(erc721a.isApprovedForAll(alice, bob), true);
    }

    function test_ERC721A_ApproveLastToken() public {
        uint256 tokenId = 9;
        vm.prank(alice);
        erc721a.approve(bob, tokenId);

        assertEq(
            erc721a.getApproved(tokenId),
            bob,
            "Fail to approve ERC721 to Bob"
        );
    }
}
