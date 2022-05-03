// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {TokenInventories} from "./TokenInventories.sol";

/**
 * @notice ERC721 implementation that utilizes token inventories.
 *
 * @author https://github.com/nfticks
 */
contract ERC721TI is ERC721, TokenInventories {
    using Address for address;

    // Amount of tokens minted
    uint256 public tokensMinted;

    // Amount of tokens burned
    uint256 public tokensBurned;

    // Mapping from token ID to inventory
    uint16[MAX_SUPPLY] internal _tokenToInventory;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    //////////////////////////////////////////////////////////////////
    //                          OVERRIDES
    /////////////////////////////////////////////////////////////////

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _getBalance(owner);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (address)
    {
        require(_exists(tokenId), "ERC721: query for nonexistent token");
        return _getInventoryOwner(_tokenToInventory[tokenId]);
    }

    /**
     * @dev See {ERC721-_exists}.
     */
    function _exists(uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        return tokenId < MAX_SUPPLY && _tokenToInventory[tokenId] != 0;
    }

    /**
     * @dev See {ERC721-_safeMint}.
     */
    function _safeMint(address to, uint256 amount) internal virtual override {
        _safeMint(to, amount, "");
    }

    /**
     * @dev See {ERC721-_safeMint}.
     */
    function _safeMint(
        address to,
        uint256 amount,
        bytes memory _data
    ) internal virtual override {
        _mint(to, amount);
        while (amount > 0) {
            unchecked {
                require(
                    checkOnERC721Received(
                        address(0),
                        to,
                        tokensMinted - amount--,
                        _data
                    ),
                    "ERC721: transfer to non ERC721Receiver implementer"
                );
            }
        }
    }

    /**
     * @dev See {ERC721-_mint}.
     */
    function _mint(address to, uint256 amount) internal virtual override {
        require(to != address(0), "ERC721: mint to the zero address");

        uint256 inventory = _getOrSubscribeInventory(to);
        uint256 tokenId = tokensMinted;

        unchecked {
            uint256 max = tokenId + amount;
            while (tokenId < max) {
                _tokenToInventory[tokenId] = uint16(inventory);
                emit Transfer(address(0), to, tokenId++);
            }
        }

        _increaseBalance(to, amount);
        tokensMinted = tokenId;
    }

    /**
     * @dev See {ERC721-_burn}.
     */
    function _burn(uint256 tokenId) internal virtual override {
        address owner = ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        delete _tokenToInventory[tokenId];
        _decreaseBalance(owner, 1);

        unchecked {
            tokensBurned++;
        }

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev See {ERC721-_transfer}.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _decreaseBalance(from, 1);
        _tokenToInventory[tokenId] = uint16(_getOrSubscribeInventory(to));
        _increaseBalance(to, 1);

        emit Transfer(from, to, tokenId);
    }

    //////////////////////////////////////////////////////////////////
    //                          COPY-PASTA
    /////////////////////////////////////////////////////////////////

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}
