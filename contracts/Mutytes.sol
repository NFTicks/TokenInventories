// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";

contract Mutytes is ERC721Enumerable {
    function mint(uint256 amount) external payable {
        _mint(_msgSender(), amount);
    }

    function safeMint(uint256 amount) external payable {
        _safeMint(_msgSender(), amount);
    }
}
