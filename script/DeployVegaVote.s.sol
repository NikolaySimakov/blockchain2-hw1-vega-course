// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/VegaVote.sol";
import "../src/VegaVoteNFT.sol";

contract DeployVegaVote is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy VegaVoteNFT
        VegaVoteNFT vegaVoteNFT = new VegaVoteNFT();
        console.log("VegaVoteNFT deployed at:", address(vegaVoteNFT));

        // Deploy VegaVote
        VegaVote vegaVote = new VegaVote();
        console.log("VegaVote deployed at:", address(vegaVote));

        vegaVote.setNFTContract(address(vegaVoteNFT));
        console.log("NFT contract set in VegaVote");

        vegaVoteNFT.transferOwnership(address(vegaVote));
        console.log("Ownership of VegaVoteNFT transferred to VegaVote");

        vm.stopBroadcast();
    }
}