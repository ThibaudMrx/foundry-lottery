//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        return deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        console2.log("DeployRaffle.s.sol:deployContract : Deploying contract");
        HelperConfig config = new HelperConfig();
        AddConsumer addConsumer = new AddConsumer();
        HelperConfig.NetworkConfig memory networkConfig = config.getConfig();

        if (networkConfig.subscriptionID != 0) {
            // Create subscription
            CreateSubscription createSubscription = new CreateSubscription();
            (networkConfig.subscriptionID, networkConfig.vrfCoordinator) =
                createSubscription.createSubscription(networkConfig.vrfCoordinator, networkConfig.account);

            // Fund subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                networkConfig.vrfCoordinator,
                networkConfig.subscriptionID,
                networkConfig.linkToken,
                networkConfig.account
            );

            config.setConfig(block.chainid, networkConfig);
        }

        vm.startBroadcast(networkConfig.account);
        Raffle raffle = new Raffle(
            networkConfig.entranceFee,
            networkConfig.interval,
            networkConfig.vrfCoordinator,
            networkConfig.gasLane,
            networkConfig.subscriptionID,
            networkConfig.callBackGasLimit
        );
        vm.stopBroadcast();
        addConsumer.addConsumer(
            address(raffle), networkConfig.vrfCoordinator, networkConfig.subscriptionID, networkConfig.account
        );
        // Not broadcasted becausde it already is inside the function
        console2.log("DeployRaffle.s.sol:deployContract : Deployed");
        return (raffle, config);
    }
}
