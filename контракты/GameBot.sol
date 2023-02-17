// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

import "./VRFv2Consumer.sol";

contract GameV1Bot {

    address private owner;
    address private bot = address(this);
    address[] private players;

    mapping(address => uint) public balances;
    mapping(address => uint) public playerIndex;
    
    uint public playerNumber = 0;
    uint public requestIndex = 0;

    enum Choice {
        Empty,
        Rock, 
        Paper, 
        Scissor
    }

    Choice public playerChoice = Choice.Empty;
    Choice public botChoice = Choice.Empty;
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function botResponseGeneration() internal {
        requestRandomWords();
        uint bigRandomNumber = requestIds[requestIndex];
        uint convertedRandomNumber = getRandom(bigRandomNumber);
        
        if(convertedRandomNumber == 1) {
            botChoice = Choice.Rock;
        } else if(convertedRandomNumber == 2) {
            botChoice = Choice.Paper;
        } else if(convertedRandomNumber == 3) {
            botChoice = Choice.Scissor;
        }
        

    }
    function verifyPlayer() public {
        require(playerIndex[msg.sender] != 0, "user exists");
        require(msg.sender != address(0), "address(0)");
        playerIndex[msg.sender] = playerNumber;
        playerNumber++;
        players.push(msg.sender);
    }

    function playVsBot(Choice choice) public payable {
        require(msg.sender != address(0), "address(0)");
        require(playerIndex[msg.sender] > 0, "user dont verify");
        require(msg.value == 0.01 ether, "not enough ethereum");

        uint currentIndexPlayer = playerIndex[msg.sender];
        address player = players[currentIndexPlayer];

        playerChoice = Choice.choice;
        botResponseGeneration();
        
        if (playerChoice == botChoice) {
            balances[player] += 0.01 ether;
        } else if (playerChoice == Choice.Rock) {
            if (botChoice == Choice.Paper) {
                // player: rock, bot: paper, bob win
                balances[bot] += 0.02 ether;
            } else {
                // player: rock, bot: scissor, alice win
                balances[player] += 0.02 ether;
            }
        } else if (playerChoice == Choice.Paper) {
            if (botChoice == Choice.Scissor) {
                // player: paper, bot: scissor, bob win
                balances[bot] += 0.02 ether;
            } else {
                // player: paper, bot: rock, alice win
                balances[player] += 0.02 ether;
            }
        } else if (playerChoice == Choice.Scissor) {
            if (botChoice == Choice.Rock) {
                // player: scissor, bot: rock, bob win
                balances[bot] += 0.02 ether;
            } else {
                // player: scissor, bot: paper, alice win
                balances[player] += 0.02 ether;
            }
        }
    }

    function claimMoney() public {
        require(balances[msg.sender] > 0);

        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        bool transferred = payable(msg.sender).send(amount);
        
        if (transferred != true) {
            balances[msg.sender] = amount;
        }
    }

    function addLiquidity() public payable onlyOwner {
        require(msg.value != 0, "not enough value");
        uint amount = msg.value;
        balances[bot] += amount;

    }

    function withdrawLiquidity(uint amount) public onlyOwner {
        require(amount > 0, "zero amount");
        balances[bot] -= amount;
        bool transferred = payable(msg.sender).send(amount);

        if (transferred != true) {
            balances[bot] += amount;
        } 
    }

}
