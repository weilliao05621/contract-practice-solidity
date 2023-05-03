// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "forge-std/Test.sol";

import {DemoErc721} from "../src/ERC721.sol";
import {DemoErc721a} from "../src/ERC721A.sol";

contract TestERC721 is Test {
    DemoErc721 erc721;
    DemoErc721a erc721a;

    address user1;

    function setUp() public {
        uint256 maxBatchSize = 10;

        erc721 = new DemoErc721(maxBatchSize);
        erc721a = new DemoErc721a(maxBatchSize);

        user1 = makeAddr("Weil");
    }

    function mint(bool isERC721) public {
        vm.startPrank(user1);
        uint256 mintAmount = 5;
        uint256 quantity = 1;

        for (uint256 i = 1; i <= mintAmount; ) {
            unchecked {
                ++i;
                if (isERC721) {
                    erc721.mint(user1, quantity);
                } else {
                    erc721a.mint(user1, quantity);
                }
            }
        }
    }

    function test_ERC721_safeMint() public {
        mint(true);
    }

    function test_ERC721A_safeMint() public {
        mint(false);
    }
}
