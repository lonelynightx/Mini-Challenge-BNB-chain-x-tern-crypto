// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract GamePlayer1vsPlayer2 {
    address immutable factory;

    constructor() {
        factory = msg.sender;
    }

    uint constant public BET_MIN = 0.0001 ether;        
    uint constant public REVEAL_TIMEOUT = 10 minutes;  
    uint public initialBet;                            
    uint private firstReveal;                          

    enum Moves {None, Rock, Paper, Scissors}
    enum Outcomes {None, PlayerA, PlayerB, Draw}   // Possible outcomes
    enum AppState {None, Registration, Active, Finished}



    // Players' addresses
    address payable playerA;
    address payable playerB;

    // check
    address public playerAaddress = playerA;
    address public playerBaddress = playerB;

    

    // Encrypted moves
    bytes32 private encrMovePlayerA;
    bytes32 private encrMovePlayerB;

    // Clear moves set only after both players have committed their encrypted moves
    Moves public movePlayerA;
    Moves public movePlayerB;
    
    AppState public appstate;

    // Bet must be greater than a minimum amount and greater than bet of first player
    modifier validBet() {
        require(msg.value >= BET_MIN, "no valid bet");
        require(initialBet == 0 || msg.value >= initialBet);
        _;
    }

    modifier notAlreadyRegistered() {
        require(msg.sender != playerA && msg.sender != playerB);
        _;
    }

    // Register a player.
    // Return player's ID upon successful registration.
    function register() public payable validBet notAlreadyRegistered returns (uint) {
        if (playerA == address(0x0)) {
            playerA    = payable(msg.sender);
            initialBet = msg.value;
            appstate = AppState.Registration;
            return 1;
        } else if (playerB == address(0x0)) {
            playerB = payable(msg.sender);
            appstate = AppState.Active;
            return 2;
        }
        return 0;
    }

    modifier isRegistered() {
        require (msg.sender == playerA || msg.sender == playerB);
        _;
    }

    // Save player's encrypted move.
    // Return 'true' if move was valid, 'false' otherwise.
    function play(bytes32 encrMove) public isRegistered returns (bool) {
        if (msg.sender == playerA && encrMovePlayerA == 0x0) {
            encrMovePlayerA = encrMove;
        } else if (msg.sender == playerB && encrMovePlayerB == 0x0) {
            encrMovePlayerB = encrMove;
        } else {
            return false;
        }
        return true;
    }

    modifier commitPhaseEnded() {
        require(encrMovePlayerA != 0x0 && encrMovePlayerB != 0x0);
        _;
    }

    // Compare clear move given by the player with saved encrypted move.
    // Return clear move upon success, 'Moves.None' otherwise.
    function reveal(string memory clearMove) public isRegistered commitPhaseEnded returns (Moves) {
        bytes32 encrMove = keccak256(abi.encodePacked(clearMove));  
        Moves move = Moves(getFirstChar(clearMove));       

        // If move invalid, exit
        if (move == Moves.None) {
            return Moves.None;
        }

        // If hashes match, clear move is saved
        if (msg.sender == playerA && encrMove == encrMovePlayerA) {
            movePlayerA = move;
        } else if (msg.sender == playerB && encrMove == encrMovePlayerB) {
            movePlayerB = move;
        } else {
            return Moves.None;
        }

        // Timer starts after first revelation from one of the player
        if (firstReveal == 0) {
            firstReveal = block.timestamp;
        }

        return move;
    }

    // Return first character of a given string.
    function getFirstChar(string memory str) private pure returns (uint) {
        bytes1 firstByte = bytes(str)[0];
        if (firstByte == 0x31) {
            return 1;
        } else if (firstByte == 0x32) {
            return 2;
        } else if (firstByte == 0x33) {
            return 3;
        } else {
            return 0;
        }
    }

    modifier revealPhaseEnded() {
        require((movePlayerA != Moves.None && movePlayerB != Moves.None) ||
                (firstReveal != 0 && block.timestamp > firstReveal + REVEAL_TIMEOUT), "reveal phase not ended");
        _;
    }

    // Compute the outcome and pay the winner(s).
    // Return the outcome.
    function getOutcome() public revealPhaseEnded returns (Outcomes) {
        Outcomes outcome;

        if (movePlayerA == movePlayerB) {
            outcome = Outcomes.Draw;
        } else if ((movePlayerA == Moves.Rock     && movePlayerB == Moves.Scissors) ||
                   (movePlayerA == Moves.Paper    && movePlayerB == Moves.Rock)     ||
                   (movePlayerA == Moves.Scissors && movePlayerB == Moves.Paper)    ||
                   (movePlayerA != Moves.None     && movePlayerB == Moves.None)) {
            outcome = Outcomes.PlayerA;
        } else {
            outcome = Outcomes.PlayerB;
        }

        address payable addrA = playerA;
        address payable addrB = playerB;
        uint betPlayerA = initialBet;
        reset();  // Reset game before paying to avoid reentrancy attacks
        pay(addrA, addrB, betPlayerA, outcome);

        return outcome;
    }

    // Pay the winner(s).
    function pay(address payable addrA, address payable addrB, uint betPlayerA, Outcomes outcome) private {
        // if player 1 loses, 3% of player 2's win will go towards deployment costs
        uint feeForTheDeployer = (address(this).balance/100)*97;
        if (outcome == Outcomes.PlayerA) {
            addrA.transfer(address(this).balance);
        } else if (outcome == Outcomes.PlayerB) {
            addrA.transfer(feeForTheDeployer);
            addrB.transfer(address(this).balance);
        } else {
            addrA.transfer(betPlayerA);
            addrB.transfer(address(this).balance);
        }

        if (getContractBalance() == 0) {
            appstate = AppState.Finished;
        }
    }

    // Reset the game.
    function reset() private {
        initialBet      = 0;
        firstReveal     = 0;
        playerA         = payable(address(0x0));
        playerB         = payable(address(0x0));
        encrMovePlayerA = 0x0;
        encrMovePlayerB = 0x0;
        movePlayerA     = Moves.None;
        movePlayerB     = Moves.None;
    }

    // Return contract balance
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    // Return player's ID
    function whoAmI() public view returns (uint) {
        if (msg.sender == playerA) {
            return 1;
        } else if (msg.sender == playerB) {
            return 2;
        } else {
            return 0;
        }
    }

    // Return 'true' if both players have commited a move, 'false' otherwise.
    function bothPlayed() public view returns (bool) {
        return (encrMovePlayerA != 0x0 && encrMovePlayerB != 0x0);
    }

    // Return 'true' if both players have revealed their move, 'false' otherwise.
    function bothRevealed() public view returns (bool) {
        return (movePlayerA != Moves.None && movePlayerB != Moves.None);
    }

    // Return time left before the end of the revelation phase.
    function revealTimeLeft() public view returns (int) {
        if (firstReveal != 0) {
            return int((firstReveal + REVEAL_TIMEOUT) - block.timestamp);
        }
        return int(REVEAL_TIMEOUT);
    }
}
