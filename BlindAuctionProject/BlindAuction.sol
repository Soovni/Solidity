// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract BlindAuction {
    struct Bid {
        bytes32 blindedBid; //암호화된 입찰가격
        uint deposit;//입찰자가 입찰할때 입금하는 금액 
    }

    // Init - 0; Bidding - 1; Reveal - 2; Done -3
    enum Phase { Init, Bidding, Reveal, Done }

    address payable public beneficiary; //경매 수익금을 받는 이의 주소
    mapping(address => Bid) public bids;  //각 주소에 대한 입찰 정보를 저장 
    mapping(address => uint) pendingReturns; // 다시 돌려주는 금액 

    Phase public currentPhase = Phase.Init;

    address public highestBidder;
    uint public highestBid;

    //경매 상태를 외부에 알리는데 사용되는 event 
    event AuctionEnded(address winner, uint highestBid);
    event BiddingStarted();
    event RevealStarted();
    event AuctionInit();

    //경매 수익자만이 함수를 호출할 수 있도록 제한
    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Only beneficiary can call this");
        _;
    }
    //경매를 생성하고, beneficiary 설정 
    constructor() {
        beneficiary = payable(msg.sender);
    }

    //경매진행시키기 
    function advancePhase() public onlyBeneficiary {
        require(currentPhase != Phase.Done, "Auction already ended");

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

    //입찰단계에서 사용자가 입찰을 할 수 있게끔 함
    function bid(bytes32 _blindedBid) public payable {
        require(currentPhase == Phase.Bidding, "Invalid phase");
        bids[msg.sender] = Bid({
            blindedBid: _blindedBid,
            deposit: msg.value
        });
    }

    // 사용자가 실제 입찰 금액을 공개, 유효한지 확인
    function reveal(uint _value, bytes32 _secret) public {
        require(currentPhase == Phase.Reveal, "Invalid phase");

        Bid storage bidToCheck = bids[msg.sender];

        if (bidToCheck.blindedBid == keccak256(abi.encodePacked(_value, _secret))) {
            uint refund = bidToCheck.deposit;
            if (_value * 1 ether > highestBid) {
                if (highestBidder != address(0)) {  //이전에 유효한 최고 입찰자가 있는지 확인 
                    // 이전 최고 입찰자에게 입찰 금액 반환
                    pendingReturns[highestBidder] += highestBid;
                }
                 // 새로운 최고 입찰자 설정
                highestBid = _value * 1 ether;
                highestBidder = msg.sender;
                refund -= _value * 1 ether;  // 입찰 금액 제외 나머지 반환
            }
             // 남은 금액 pendingReturns에 추가
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
        if (amount > 0) {  //반환할 금액이 실제로 있는지 확인 
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
    }

    //가장 높은 bid beneficiary 에게 전달 
    function auctionEnd() public onlyBeneficiary {
        require(currentPhase == Phase.Done, "Invalid phase");
        if (highestBidder != address(0)) {
            beneficiary.transfer(highestBid);
        }
        emit AuctionEnded(highestBidder, highestBid);
    }
}
