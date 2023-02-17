// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

contract GameV1PlayerVsPlayer {
   
    uint256 public initializeNumber = 0;
    uint256 public startBlock = block.number;
    
    address private GameFactory = "ВСТАВИТЬ АДРЕС ФАБРИКИ";
    address private player1;
    address private player2;

    bytes32 player1Hash; 
    bytes32 player2Hash; 

    enum Choice {
        Empty,
        Rock, 
        Paper, 
        Scissor
    }
    
    Choice public player1Choice = Choice.Empty;
    Choice public player2Choice = Choice.Empty;

    bool gameEnded = false;

    mapping(address=>uint) public balances;

    // commit the choice (Rock / Paper / Scissor)

    function initializePlayer() public {
        if(initializeNumber == 0) {
            player1 = msg.sender;
            initializeNumber++;
        } else if(initializeNumber == 1) {
            player2 = msg.sender;
        }

    }
    

    function commitChoice(bytes32 hash) public payable {
        require(block.number < (startBlock + 100));
        require((msg.sender == player1 && player1Hash == 0) || (msg.sender == player2 && player2Hash == 0), "not player1 or player2");
        require(msg.value == 0.01 ether, "please pay to participate");

        if(msg.sender == player1) {
            player1Hash = hash;
        } else {
            player2Hash = hash;
        }
    }

    // reveal the choice (Rock / Paper / Scissor)
    function revealChoice(Choice choice, uint nonce) public {
        require(block.number >= (startBlock + 100) && block.number < (startBlock + 200));
        require(msg.sender == player1 || msg.sender == player2, "not player1 or player2");
        require(player1Hash != 0 && player2Hash != 0, "someone did not submit hash");
        require(choice != Choice.Empty, "have to choose Rock/Paper/Scissor");
        
        if(msg.sender == player1) {
            if (player1Hash == sha256(abi.encodePacked(choice, nonce))) {
                player1Choice = choice;
            }
        } else {
            if (player2Hash == sha256(abi.encodePacked(choice, nonce))) {
                player2Choice = choice;
            }
        }
    }

    // check the result
    function findResult() public {
        require(block.number > (startBlock + 200));
        require(!gameEnded, "can only compute result once");
        require(player1Choice != Choice.Empty && player2Choice != Choice.Empty, "someone did not reveal their choice");

        // draw
        if (player1Choice == player2Choice) {
            balances[player1] += 0.01 ether;
            balances[player2] += 0.01 ether;
        } else if (player1Choice == Choice.Rock) {
            if (player2Choice == Choice.Paper) {
                // player1: rock, player2: paper, bob win
                balances[player2] += 0.02 ether;
            } else {
                // player1: rock, player2: scissor, alice win
                balances[player1] += 0.02 ether;
            }
        } else if (player1Choice == Choice.Paper) {
            if (player2Choice == Choice.Scissor) {
                // player1: paper, player2: scissor, bob win
                balances[player2] += 0.02 ether;
            } else {
                // player1: paper, player2: rock, alice win
                balances[player1] += 0.02 ether;
            }
        } else if (player1Choice == Choice.Scissor) {
            if (player2Choice == Choice.Rock) {
                // player1: scissor, player2: rock, bob win
                balances[player2] += 0.02 ether;
            } else {
                // player1: scissor, player2: paper, alice win
                balances[player1] += 0.02 ether;
            }
        }

        gameEnded = true;
    }

    // in case either party did not participate
    function refundDeposit() public {
        bool didNotSubmitHash = block.number >= (startBlock + 100) && (player1Hash == 0 || player2Hash == 0);
        bool didNotRevealChoice = block.number >= (startBlock + 200) && (player1Choice == Choice.Empty || player2Choice == Choice.Empty);

        require(didNotSubmitHash || didNotRevealChoice);
        require(address(this).balance >= 0.01 ether);

        if (block.number >= (startBlock + 200)) {
            if (player1Choice == Choice.Empty && player2Choice != Choice.Empty) {
                balances[player2] += 0.02 ether;
            } else if (player1Choice != Choice.Empty && player2Choice == Choice.Empty) {
                balances[player1] += 0.02 ether;
            } else {
                balances[player1] += 0.01 ether;
                balances[player2] += 0.01 ether;
            }
        } else if (block.number >= (startBlock + 100)) {
            if (player1Hash == 0 && player2Hash != 0) {
                balances[player2] += 0.01 ether;
            } else if (player1Hash != 0 && player2Hash == 0) {
                balances[player1] += 0.01 ether;
            }
        }
    }

    function claimMoney() public {
        require(msg.sender == player1 || msg.sender == player2, "not Alice or Bob");
        require(balances[msg.sender] > 0);

        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        bool transferred = payable(msg.sender).send(amount);
        
        if (transferred != true) {
            balances[msg.sender] = amount;
        }

        if(balances[player1] == 0 && balances[player2] == 0) {
            selfdestruct(payable(GameFactory));
        }
    }

}
