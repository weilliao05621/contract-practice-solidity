// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "../lib/ERC721A/contracts/ERC721A.sol";

contract DemoErc721a is ERC721A {
    constructor() ERC721A("Token", "TKN") {}

    function mint(address to, uint256 quantity) public {
        _safeMint(to, quantity);
    }
}
