// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {ERC721TI} from "./ERC721TI.sol";
import {IERC721Enumerable, IERC165} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @notice ERC721 Enumerable extension that that utilizes token inventories.
 *
 * @author https://github.com/nfticks
 */
contract ERC721EnumerableTI is ERC721TI, IERC721Enumerable {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721TI, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return tokensMinted - tokensBurned;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );

        uint256 i;
        for (uint256 j; true; i++) {
            if (_tokenToInventory[i] != 0 && j++ == index) {
                break;
            }
        }

        return i;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < balanceOf(owner),
            "ERC721Enumerable: index query for nonexistent token"
        );

        uint256 i;
        for (uint256 count; count <= index; i++) {
            if (_getInventoryOwner(_tokenToInventory[i]) == owner) {
                count++;
            }
        }

        return i - 1;
    }
}
