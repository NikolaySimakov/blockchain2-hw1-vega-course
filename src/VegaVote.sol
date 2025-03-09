// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract VegaVote is ERC20, Ownable {
    
    struct Vote {
        uint256 id;
        string description;
        uint256 deadline;
        uint256 votingThreshold;
        uint256 totalYes;
        uint256 totalNo;
        bool isActive;
    }

    struct Staker {
        uint256 amount;
        uint256 stakingPeriod;
        uint256 stakingStartTime;
    }

    mapping(uint256 => Vote) public votes;
    mapping(address => Staker) public stakers;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    uint256 public voteCounter;
    address public nftContract;

    event VoteCreated(uint256 indexed voteId, string description, uint256 deadline, uint256 threshold);
    event VoteCasted(uint256 indexed voteId, address indexed voter, bool vote);
    event VoteConcluded(uint256 indexed voteId, uint256 totalYes, uint256 totalNo);
    event NFTMinted(uint256 indexed voteId, address indexed recipient, uint256 tokenId);

    constructor() ERC20("VegaVote", "VGV") Ownable(msg.sender) {}

    function stakeTokens(uint256 amount, uint256 stakingPeriod) external {
        require(stakingPeriod <= 4 * 365 days, "Staking period cannot exceed 4 years");
        require(amount > 0, "Amount must be greater than 0");

        _transfer(msg.sender, address(this), amount);
        stakers[msg.sender] = Staker({
            amount: amount,
            stakingPeriod: stakingPeriod,
            stakingStartTime: block.timestamp
        });
    }

    function createVote(string memory description, uint256 deadline, uint256 votingThreshold) external onlyOwner {
        require(deadline > block.timestamp, "Deadline must be in the future");

        voteCounter++;
        votes[voteCounter] = Vote({
            id: voteCounter,
            description: description,
            deadline: deadline,
            votingThreshold: votingThreshold,
            totalYes: 0,
            totalNo: 0,
            isActive: true
        });

        emit VoteCreated(voteCounter, description, deadline, votingThreshold);
    }

    function castVote(uint256 voteId, bool vote) external {
        require(votes[voteId].isActive, "Vote is not active");
        require(block.timestamp <= votes[voteId].deadline, "Voting deadline has passed");
        require(!hasVoted[voteId][msg.sender], "Already voted");

        Staker memory staker = stakers[msg.sender];
        require(staker.amount > 0, "No staked tokens");

        uint256 votingPower = staker.amount.mul(staker.stakingPeriod ** 2);
        if (vote) {
            votes[voteId].totalYes = votes[voteId].totalYes.add(votingPower);
        } else {
            votes[voteId].totalNo = votes[voteId].totalNo.add(votingPower);
        }

        hasVoted[voteId][msg.sender] = true;
        emit VoteCasted(voteId, msg.sender, vote);

        _checkVoteThreshold(voteId);
    }

    function _checkVoteThreshold(uint256 voteId) private {
        Vote storage vote = votes[voteId];
        uint256 totalVotes = vote.totalYes.add(vote.totalNo);

        if (totalVotes >= vote.votingThreshold || block.timestamp >= vote.deadline) {
            vote.isActive = false;
            emit VoteConcluded(voteId, vote.totalYes, vote.totalNo);

            _mintNFT(voteId);
        }
    }

    function _mintNFT(uint256 voteId) private {
        require(nftContract != address(0), "NFT contract not set");

        string memory metadata = string(abi.encodePacked(
            "Vote ID: ", uint2str(voteId), 
            ", Yes: ", uint2str(votes[voteId].totalYes), 
            ", No: ", uint2str(votes[voteId].totalNo)
        ));

        uint256 tokenId = uint256(keccak256(abi.encodePacked(voteId, block.timestamp)));
        IVegaVoteNFT(nftContract).mintNFT(owner(), tokenId, metadata);

        emit NFTMinted(voteId, owner(), tokenId);
    }

    function setNFTContract(address _nftContract) external onlyOwner {
        nftContract = _nftContract;
    }

    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (_i != 0) {
            k--;
            bstr[k] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }
}

interface IVegaVoteNFT {
    function mintNFT(address to, uint256 tokenId, string memory metadata) external;
}
