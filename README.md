# ERC721 Token Inventories

A modified implementation of OpenZeppelin's ERC721/Enumerable contracts that makes use of an intermediate token inventories layer to resolve ownership, effectively reducing gas expenses for token interactions.

[Benchmarks](ERC721.md) taken with [solidity-benchmarks](https://github.com/alephao/solidity-benchmarks)

### Motivation

OZ's ERC721 implementation is designed to support a wide range of projects. Ownership resolution is done by writing an address to storage once per token, which becomes redundant when a single address acquires multiple tokens. If we apply some common limitations and avoid writing owner addresses multiple times, we can incerase gas efficiency.

### Application

We introduce a subscription-based inventory system that assigns owner addresses to sequential IDs in range [1, MAX_SUPPLY] inclusive, where MAX_SUPPLY < type(uint16).max - 1. The number of required inventories is at-most MAX_SUPPLY + 1, since ID 0 is assigned to the zero-address.

Using this approach we write an owner's address to storage once. Writing the owner's uint16 ID to storage multiple times is more efficient, since we will now be updating the same uint256 slot.
