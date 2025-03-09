// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VegaVoteNFT is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public tokenCounter;

    constructor() ERC721("VegaVoteNFT", "VVN") Ownable(msg.sender) {}

    function mintNFT(address to, uint256 tokenId, string memory metadata) external onlyOwner {
        _mint(to, tokenId);
        tokenCounter++;
    }
}