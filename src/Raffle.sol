// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A Simple Raffle contract
 * @author Thibaud Merieux
 * @notice This contract is for creating a simple Raffle
 * @dev Implements Chainlink VRF2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    error Raffle_SendMoreEthToEnterRaffle();

    uint256 private immutable i_entranceFee;
    uint256 private s_lastTimestamp;
    uint256 private immutable i_interval;
    address payable[] private s_players;

    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint256 subId;
    uint16 requestConfirmations;
    uint32 callbackGasLimit;

    /** Events */
    event RaffleEntered(address indexed player);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gaslane,
        uint256 subscriptionId
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimestamp = block.timestamp;
        i_keyHash = gaslane;
        i_subscriptionId = subscriptionId;
    }

    function enterRaffle() external payable {
        if (msg.value <= i_entranceFee) {
            revert Raffle_SendMoreEthToEnterRaffle();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    // 1. Get a random number
    // 2. Use the random number to pick a winner
    // 3. Be called automatically (?)
    function pickWinner() external {
        if (block.timestamp - s_lastTimestamp < i_interval) {
            revert();
        }

        VRFV2PlusClient.RandomWordsRequest requestId = s_vrfCoordinator
            .requestRandomWords(
                VRFV2PlusClient.RandomWordsRequest({
                    keyHash: i_keyHash,
                    subId: s_subscriptionId,
                    requestConfirmations: requestConfirmations,
                    callbackGasLimit: callbackGasLimit,
                    numWords: numWords,
                    extraArgs: VRFV2PlusClient._argsToBytes(
                        // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                        VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                    )
                })
            );
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {}

    /** Getter functions */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
