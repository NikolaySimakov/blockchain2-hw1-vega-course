// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract VegaVoteNFT is ERC721, Ownable {
    uint256 public tokenCounter;

    constructor() ERC721("VegaVoteNFT", "VVN") Ownable(msg.sender) {}

    function mintNFT(address to, uint256 tokenId, string memory metadata) external onlyOwner {
        _mint(to, tokenId);
        tokenCounter++;
    }
}