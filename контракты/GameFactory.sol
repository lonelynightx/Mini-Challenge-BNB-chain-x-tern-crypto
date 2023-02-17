// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

import "./GamePlayerVsPlayer.sol";

contract GameFactory {
    address private owner;
    uint public createdCount = 0;

    event gameCreated(address indexed creator, address game, uint count);
    constructor() {
        owner = msg.sender;
    }

    function createGame() public {
        address game;
        bytes memory bytecode = type(GameV1).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, createdCount));
        
        assembly {
            game := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        createdCount++;
        emit gameCreated(msg.sender, game, createdCount);
    }
}
