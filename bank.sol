// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract Bank {
        address private owner;
        mapping(address => uint256) private balances;

        event Deposit(address indexed depositor, uint256 amount);
        event Withdrawal(address indexed withdrawer, uint256 amount);

        constructor () {
            owner=msg.sender;

        }

        modifier onlyOwner(){
            require(msg.sender == owner, "Caller is not the owner");
            _;
        }
        function deposit() public payable{
            require(msg.value >0, "Deposit amount must be greater than 0");
            balances[msg.sender]+=msg.value;
            emit Deposit(msg.sender,msg.value);
        }
        function withdraw(uint256 amount) public{
            require(balances[msg.sender]>=amount, "Insufficient balance");
            balances[msg.sender]-=amount;
            payable(msg.sender).transfer(amount);
            emit Withdrawal(msg.sender,amount);

        }
        function getBalance()public view returns(uint256){
            return balances[msg.sender];
        }
        function getContractBalance() public view onlyOwner returns (uint256){
            return address(this).balance;
        }

}