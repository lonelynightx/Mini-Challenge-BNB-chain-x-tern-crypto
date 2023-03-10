// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

import "./VRFv2Consumer.sol";

contract GameBotV1 {
    VRFv2Consumer public VRFv2;

    address private owner;
    address private bot = address(this);
    address[] private players;

    mapping(address => uint) public balances;
    mapping(address => uint) public playerIndex;
    mapping(address => bool) public verify;
    
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
    constructor(address VRF) payable {
        require(msg.value == 0.1 ether, "insufficient ethers");
        balances[bot] = 0.1 ether;
        VRFv2 = VRFv2Consumer(VRF);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "you don't have the rights of an owner");
        _;
    }

    function botResponseGeneration() internal {
        VRFv2.requestRandomWords();
        uint bigRandomNumber = VRFv2.requestIds(requestIndex);
        uint convertedRandomNumber = VRFv2.getRandom(bigRandomNumber);
        requestIndex++;
        
        if(convertedRandomNumber == 1) {
            botChoice = Choice.Rock;
        } else if(convertedRandomNumber == 2) {
            botChoice = Choice.Paper;
        } else if(convertedRandomNumber == 3) {
            botChoice = Choice.Scissor;
        }
        

    }
    function verifyPlayer() public {   
        require(verify[msg.sender] != true, "user is already registered");
        playerIndex[msg.sender] = playerNumber;  
        playerNumber++;
        verify[msg.sender] = true;  
        players.push(msg.sender);  
    }

    function playVsBot(Choice choice) public payable {
        require(verify[msg.sender] == true, "user dont verify");
        require(msg.value <= getMaxRate(), "value is greater than the maximum bid");

        uint rate = msg.value;
        uint currentIndexPlayer = playerIndex[msg.sender];
        address player = players[currentIndexPlayer];

        playerChoice = choice;
        botResponseGeneration();
        
        if (playerChoice == botChoice) {
            balances[player] += rate;
        } else if (playerChoice == Choice.Rock) {
            if (botChoice == Choice.Paper) {
                // player: rock, bot: paper, bot win
                balances[bot] += rate;
            } else {
                // player: rock, bot: scissor, player win
                balances[bot] -= rate;
                balances[player] += rate*2;
            }
        } else if (playerChoice == Choice.Paper) {
            if (botChoice == Choice.Scissor) {
                // player: paper, bot: scissor, bot win
                balances[bot] += rate;
            } else {
                // player: paper, bot: rock, player win
                balances[bot] -= rate;
                balances[player] += rate*2;
            }
        } else if (playerChoice == Choice.Scissor) {
            if (botChoice == Choice.Rock) {
                // player: scissor, bot: rock, bot win
                balances[bot] += rate;
            } else {
                // player: scissor, bot: paper, player win
                balances[bot] -= rate;
                balances[player] += rate*2;
            }
        }
    }

    function claimMoney() public {
        require(balances[msg.sender] > 0, "your balance == 0");

        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        bool transferred = payable(msg.sender).send(amount);
        require(transferred, "failed to send Ether");
    }

    function addLiquidity() public payable onlyOwner {
        require(msg.value != 0, "not enough value");
        uint amount = msg.value;
        balances[bot] += amount;

    }

    function withdrawLiquidity(uint amount) public onlyOwner {
        require(balances[bot] >= amount, "amount is greater than the balance");
        balances[bot] -= amount;
        bool transferred = payable(msg.sender).send(amount);
        require(transferred, "Failed to send Ether");
    }

    function getMaxRate() public returns(uint) {
        uint maxRate = (balances[bot])/2;
        return maxRate;
    }
}
