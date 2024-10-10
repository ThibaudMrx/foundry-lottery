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
        address vrfCoordinator = config.getNetworkConfigByChainId(block.chainid).vrfCoordinator;
        address account = config.getNetworkConfigByChainId(block.chainid).account;
        (uint256 subID,) = createSubscription(vrfCoordinator, account);
        return (subID, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator, address account) public returns (uint256, address) {
        vm.startBroadcast(account);
        uint256 subID = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        return (subID, vrfCoordinator);
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 200 ether; // 0.1 LINK

    function run() external {
        fundSubscriptionUsingConfig();
    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig config = new HelperConfig();
        address vrfCoordinator = config.getConfig().vrfCoordinator;
        uint256 subscriptionID = config.getConfig().subscriptionID;
        address linkToken = config.getConfig().linkToken;
        address account = config.getConfig().account;
        fundSubscription(vrfCoordinator, subscriptionID, linkToken, account);
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionID, address linkToken, address account)
        public
    {
        if (block.chainid == CodeConstants.LOCAL_CHAIN_ID) {
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionID, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionID));
            vm.stopBroadcast();
        }
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
        address account = config.getConfig().account;
        addConsumer(mostRecentRaffleDeployed, vrfCoordinator, subscriptionID, account);
    }

    function addConsumer(address mostRecentRaffleDeployed, address vrfCoordinator, uint256 subID, address account)
        public
    {
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subID, mostRecentRaffleDeployed);
        vm.stopBroadcast();
    }
}
