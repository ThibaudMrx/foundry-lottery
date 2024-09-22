//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/**
 * @title A Simple Raffle contract
 * @author Thibaud Merieux
 * @notice This contract is for creating a simple Raffle
 * @dev Implements Chainlink VRF2.5
 */
contract Raffle {
    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle(uint256 entranceFee) public {}

    function pickWinner() public {}
}
