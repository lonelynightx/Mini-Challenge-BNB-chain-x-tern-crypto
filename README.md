# Mini-Challenge-BNB-chain-x-tern-crypto

## About
This is a decentralized "Stone-Scissors-Paper" game app. 
###### There are 2 modes:
1. The player can battle with another player.
2. The player can fight against a smart contract.

###### Dapp consists of 4 smart contracts:
1. GameFactory.sol - contract factory for 1vs1 games. Creates a separate contract for each new game.
2. GamePlayerVsPlayer.sol - is created by the contract factory, in this contract players fight 1 vs 1.
3. GameBot.sol - contract to play against a smart contract.
4. VRFv2Consumer.sol - 
