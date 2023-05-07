// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract DemoErc721 is ERC721Enumerable {
    constructor() ERC721("Token", "TKN") {}

    function mint(address to, uint256 quantity) public {
        for (uint256 i = 0; i < quantity; ) {
            _safeMint(to, totalSupply());
            unchecked {
                ++i;
            }
        }
    }
}
