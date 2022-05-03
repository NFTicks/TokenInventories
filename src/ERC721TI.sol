// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ERC165, IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {TokenInventories} from "./TokenInventories.sol";

/**
 * @notice ERC721 implementation that utilizes token inventories.
 *
 * @author https://github.com/nfticks
 */
contract ERC721TI is Context, ERC165, IERC721, TokenInventories {
    using Address for address;

    // Amount of tokens minted
    uint256 public tokensMinted;

    // Amount of tokens burned
    uint256 public tokensBurned;

    // Mapping from token ID to inventory
    uint16[MAX_SUPPLY] internal _tokenToInventory;

    //////////////////////////////////////////////////////////////////
    //                          OVERRIDES
    /////////////////////////////////////////////////////////////////

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

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
            "ERC721TI: balance query for the zero address"
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
        override
        returns (address)
    {
        require(_exists(tokenId), "ERC721TI: query for nonexistent token");
        return _getInventoryOwner(_tokenToInventory[tokenId]);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721TI: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721TI: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721TI: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721TI: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721TI: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev See {ERC721-_safeTransfer}.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721TI: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev See {ERC721-_approve}.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev See {ERC721-_setApprovalForAll}.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721TI: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev See {ERC721-_exists}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < MAX_SUPPLY && _tokenToInventory[tokenId] != 0;
    }

    /**
     * @dev See {ERC721-_isApprovedOrOwner}.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721TI: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @dev See {ERC721-_safeMint}.
     */
    function _safeMint(address to, uint256 amount) internal virtual {
        _safeMint(to, amount, "");
    }

    /**
     * @dev See {ERC721-_safeMint}.
     */
    function _safeMint(
        address to,
        uint256 amount,
        bytes memory _data
    ) internal virtual {
        _mint(to, amount);
        while (amount > 0) {
            unchecked {
                require(
                    _checkOnERC721Received(
                        address(0),
                        to,
                        tokensMinted - amount--,
                        _data
                    ),
                    "ERC721TI: transfer to non ERC721Receiver implementer"
                );
            }
        }
    }

    /**
     * @dev See {ERC721-_mint}.
     */
    function _mint(address to, uint256 amount) internal virtual {
        require(to != address(0), "ERC721TI: mint to the zero address");

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
    function _burn(uint256 tokenId) internal virtual {
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
    ) internal virtual {
        require(
            ownerOf(tokenId) == from,
            "ERC721TI: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721TI: transfer to the zero address");

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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
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
                        "ERC721TI: transfer to non ERC721Receiver implementer"
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
