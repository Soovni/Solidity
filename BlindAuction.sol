// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract BlindAuction {
    struct Bid {
        bytes32 blindedBid;
        uint deposit;
    }

    //phase 0,1,2,3
    enum Phase { Init, Bidding, Reveal, Done }

    address payable public beneficiary;
    Phase public currentPhase = Phase.Init;

    mapping(address => Bid) public bids;
    mapping(address => uint) pendingReturns; // 돌려줄 금액

    address public highestBidder;
    uint public highestBid;

    event AuctionEnded(address winner, uint highestBid);
    event BiddingStarted();
    event RevealStarted();
    event AuctionInit();

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Only beneficiary can call this");
        _;
    }

    modifier onlyinPhase(Phase _phase) {
        require(currentPhase == _phase, "Phase Invalid");
        _;
    }

    constructor() {
        beneficiary = payable(msg.sender);
    }

    function advancePhase() public onlyBeneficiary {
        if (currentPhase == Phase.Done) {
            revert("Auction already ended");
        }
        if (currentPhase == Phase.Init) {
            currentPhase = Phase.Bidding;
            emit BiddingStarted();
        } else if (currentPhase == Phase.Bidding) {
            currentPhase = Phase.Reveal;
            emit RevealStarted();
        } else if (currentPhase == Phase.Reveal) {
            currentPhase = Phase.Done;
            emit AuctionEnded(highestBidder, highestBid);
        }
    }

    function bid(bytes32 _blindedBid) public payable onlyinPhase(Phase.Bidding) {
        bids[msg.sender] = Bid({
            blindedBid: _blindedBid,
            deposit: msg.value
        });
    }

    function reveal(uint _value, bytes32 _secret) public onlyinPhase(Phase.Reveal) {
        Bid storage bidToCheck = bids[msg.sender];
        if (bidToCheck.blindedBid == keccak256(abi.encodePacked(_value, _secret))) {
            uint refund = bidToCheck.deposit;
            if (_value * 1 ether > highestBid) {
                if (highestBidder != address(0)) {
                    // 이전 최고 입찰자에게 입찰 금액 반환
                    pendingReturns[highestBidder] += highestBid;
                }
                // 새로운 최고 입찰자 설정
                highestBid = _value * 1 ether;
                highestBidder = msg.sender;
                refund -= _value * 1 ether; // 입찰 금액 제외 나머지 반환
            }
            // 남은 금액을 pendingReturns에 추가
            if (refund > 0) {
                pendingReturns[msg.sender] += refund;
            }
        } else {
            // 해시가 다르면 전체 예치금 반환 
            pendingReturns[msg.sender] += bidToCheck.deposit;
        }
        bidToCheck.blindedBid = bytes32(0);
    }

    function withdraw() public { // winning bid 아닌거 반환 
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
    }
    //가장 높은 bid beneficiary 에게 전달 
    function auctionEnd() public onlyBeneficiary onlyinPhase(Phase.Done) {
        if (highestBidder != address(0)) {
            beneficiary.transfer(highestBid);
        }
        emit AuctionEnded(highestBidder, highestBid);
    }

    
}

//해보고싶은거-> 남은 경매시간 알려주는것 

