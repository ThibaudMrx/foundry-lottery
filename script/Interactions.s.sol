// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script, HelperConfig {
    function run() external returns (uint256, address) {
        return createSubscriptionUsingConfig();
    }

    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig config = new HelperConfig();
        address vrfCoordinatior = config.getConfig().vrfCoordinator;
        (uint256 subID,) = createSubscription(vrfCoordinatior);
        return (subID, vrfCoordinatior);
    }

    function createSubscription(address vrfCoordinator) public returns (uint256, address) {
        console2.log("Creating subscription on chain ID : ", block.chainid);
        vm.startBroadcast();
        uint256 subID = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console2.log("Your subscription ID is : ", subID);
        console2.log("Please update the subscription ID in your HelperConfig.s.sol");
        return (subID, vrfCoordinator);
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 0.2 ether; // 0.1 LINK

    function run() external {
        fundSubscriptionUsingConfig();
    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig config = new HelperConfig();
        address vrfCoordinator = config.getConfig().vrfCoordinator;
        uint256 subscriptionID = config.getConfig().subscriptionID;
        address linkToken = config.getConfig().linkToken;
        fundSubscription(vrfCoordinator, subscriptionID, linkToken);
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionID, address linkToken) public {
        console2.log("Funding subscription  : ", subscriptionID);
        console2.log("Using vrfCoordinator : ", vrfCoordinator);
        console2.log("Using linkToken : ", linkToken);
        console2.log("Using this ammount : ", FUND_AMOUNT);
        console2.log("On chainID : ", block.chainid);
        if (block.chainid == CodeConstants.LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionID, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            console2.log("Balance LINK emetteur : ", LinkToken(linkToken).balanceOf(msg.sender));
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionID));
            vm.stopBroadcast();
        }
        console2.log("Funding done : ");
    }
}

contract AddConsumer is Script {
    function run() external {
        address mostRecentRaffleDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentRaffleDeployed);
    }

    function addConsumerUsingConfig(address mostRecentRaffleDeployed) public {
        HelperConfig config = new HelperConfig();
        address vrfCoordinator = config.getConfig().vrfCoordinator;
        uint256 subscriptionID = config.getConfig().subscriptionID;
        addConsumer(mostRecentRaffleDeployed, vrfCoordinator, subscriptionID);
    }

    function addConsumer(address mostRecentRaffleDeployed, address vrfCoordinator, uint256 subID) public {
        console2.log("AddConsumer : Adding this raffle contract : ", mostRecentRaffleDeployed);
        console2.log("AddConsumer : Too this VRF Coordinator : ", vrfCoordinator);
        console2.log("AddConsumer : Using this subID : ", subID);
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subID, mostRecentRaffleDeployed);
        vm.stopBroadcast();
    }
}
