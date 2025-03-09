// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "lib/forge-std/Test.sol";
import "../src/VegaVote.sol";
import "../src/VegaVoteNFT.sol";

contract VegaVoteTest is Test {
    VegaVote public vegaVote;
    VegaVoteNFT public vegaVoteNFT;
    address public admin = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);

    function setUp() public {
        // Deploy contracts
        vegaVote = new VegaVote();
        vegaVoteNFT = new VegaVoteNFT();

        // Set NFT contract address in VegaVote
        vegaVote.setNFTContract(address(vegaVoteNFT));

        // Transfer ownership to admin
        vegaVote.transferOwnership(admin);
        vegaVoteNFT.transferOwnership(admin);

        // Mint some VegaVote tokens to users
        uint256 initialSupply = 1000 ether;
        vegaVote.mint(user1, initialSupply);
        vegaVote.mint(user2, initialSupply);
    }

    function testStakeTokens() public {
        vm.prank(user1);
        vegaVote.stakeTokens(100 ether, 365 days);

        (uint256 amount, uint256 period, ) = vegaVote.stakers(user1);
        assertEq(amount, 100 ether, "Staked amount should be 100 ether");
        assertEq(period, 365 days, "Staking period should be 365 days");
    }

    function testCreateVote() public {
        vm.prank(admin);
        vegaVote.createVote("Should we upgrade the system?", block.timestamp + 7 days, 1000 ether);

        VegaVote.Vote memory vote = vegaVote.votes(1);
        assertEq(vote.description, "Should we upgrade the system?", "Vote description mismatch");
        assertEq(vote.deadline, block.timestamp + 7 days, "Vote deadline mismatch");
        assertEq(vote.votingThreshold, 1000 ether, "Voting threshold mismatch");
        assertTrue(vote.isActive, "Vote should be active");
    }

    function testCastVote() public {
        // Stake tokens
        vm.prank(user1);
        vegaVote.stakeTokens(100 ether, 365 days);

        // Create a vote
        vm.prank(admin);
        vegaVote.createVote("Should we upgrade the system?", block.timestamp + 7 days, 1000 ether);

        // Cast a vote
        vm.prank(user1);
        vegaVote.castVote(1, true);

        VegaVote.Vote memory vote = vegaVote.votes(1);
        assertEq(vote.totalYes, 100 ether * (365 days ** 2), "Total 'Yes' votes mismatch");
        assertEq(vote.totalNo, 0, "Total 'No' votes should be 0");
    }

    function testVoteConcludedByThreshold() public {
        // Stake tokens
        vm.prank(user1);
        vegaVote.stakeTokens(100 ether, 365 days);
        vm.prank(user2);
        vegaVote.stakeTokens(200 ether, 365 days);

        // Create a vote with a low threshold
        vm.prank(admin);
        vegaVote.createVote("Should we upgrade the system?", block.timestamp + 7 days, 100 ether);

        // Cast votes
        vm.prank(user1);
        vegaVote.castVote(1, true);
        vm.prank(user2);
        vegaVote.castVote(1, true);

        VegaVote.Vote memory vote = vegaVote.votes(1);
        assertFalse(vote.isActive, "Vote should be concluded");
        assertEq(vote.totalYes, 300 ether * (365 days ** 2), "Total 'Yes' votes mismatch");
    }

    function testVoteConcludedByDeadline() public {
        // Stake tokens
        vm.prank(user1);
        vegaVote.stakeTokens(100 ether, 365 days);

        // Create a vote
        vm.prank(admin);
        vegaVote.createVote("Should we upgrade the system?", block.timestamp + 7 days, 1000 ether);

        // Fast-forward time to after the deadline
        vm.warp(block.timestamp + 8 days);

        // Cast a vote (should fail because the deadline has passed)
        vm.prank(user1);
        vm.expectRevert("Voting deadline has passed");
        vegaVote.castVote(1, true);

        VegaVote.Vote memory vote = vegaVote.votes(1);
        assertFalse(vote.isActive, "Vote should be concluded");
    }

    function testNFTMintedAfterVoteConclusion() public {
        // Stake tokens
        vm.prank(user1);
        vegaVote.stakeTokens(100 ether, 365 days);

        // Create a vote
        vm.prank(admin);
        vegaVote.createVote("Should we upgrade the system?", block.timestamp + 7 days, 100 ether);

        // Cast a vote
        vm.prank(user1);
        vegaVote.castVote(1, true);

        // Check if NFT was minted
        uint256 tokenId = uint256(keccak256(abi.encodePacked(1, block.timestamp)));
        assertEq(vegaVoteNFT.ownerOf(tokenId), admin, "NFT should be minted to admin");
    }

    function testOnlyAdminCanCreateVote() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        vegaVote.createVote("Should we upgrade the system?", block.timestamp + 7 days, 1000 ether);
    }

    function testCannotStakeZeroTokens() public {
        vm.prank(user1);
        vm.expectRevert("Amount must be greater than 0");
        vegaVote.stakeTokens(0, 365 days);
    }

    function testCannotStakeForMoreThan4Years() public {
        vm.prank(user1);
        vm.expectRevert("Staking period cannot exceed 4 years");
        vegaVote.stakeTokens(100 ether, 5 * 365 days);
    }
}