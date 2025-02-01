// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Lottery {   
    event PlayerEntered(address indexed player);
    event WinnerSelected(address indexed winner);

    address public manager;
    address[] public players;
    bool public isBettingOpen = true;

    modifier restricted() {
        require(msg.sender == manager, "Only the manager can call this function");
        _;
    }

    constructor() {
        manager = msg.sender;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function checkDup() private view returns (bool) {
        for (uint i = 0; i < players.length; i++) {
            if (players[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function enter() public payable {
        require(isBettingOpen, "Betting is not open at this time");
        require(msg.value == 1 ether, "Only 1 Ether is Allowed");
        require(msg.sender != manager, "Manager cannot participate");

        if (!checkDup()) {
            players.push(msg.sender);
            emit PlayerEntered(msg.sender);
        }
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.number, block.timestamp, players.length)));
    }

    function pickWinner() public restricted {
        uint index = random() % players.length;
        address winner = players[index];
        delete players;
        payable(winner).transfer(address(this).balance);
        emit WinnerSelected(winner);
    }

    function toggleBetting() public restricted {
        isBettingOpen = !isBettingOpen;
    }
}



