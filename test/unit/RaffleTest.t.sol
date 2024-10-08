// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";
import {console2} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

contract RaffleTest is Test {
    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed player);

    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    LinkToken linkToken;
    bytes32 gasLane;
    uint32 callBackGasLimit;
    uint256 subscriptionID;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 1000 ether;
    uint256 public constant SUBSCIPTION_FUND_AMMOUNT = 200 ether;

    modifier playerEnteredRaffle() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.deployContract();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getConfig();
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);

        entranceFee = networkConfig.entranceFee;
        interval = networkConfig.interval;
        vrfCoordinator = networkConfig.vrfCoordinator;
        gasLane = networkConfig.gasLane;
        callBackGasLimit = networkConfig.callBackGasLimit;
        subscriptionID = networkConfig.subscriptionID;
        linkToken = LinkToken(networkConfig.linkToken);

        vm.startPrank(PLAYER);
        if (block.chainid == 31337) {
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionID, SUBSCIPTION_FUND_AMMOUNT);
        } else {
            LinkToken(linkToken).transferAndCall(vrfCoordinator, SUBSCIPTION_FUND_AMMOUNT, abi.encode(subscriptionID));
        }
        linkToken.approve(vrfCoordinator, SUBSCIPTION_FUND_AMMOUNT);
        vm.stopPrank();
    }

    function testRaffleInitialisesInOpenState() external view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenYouDontPayEnough() external {
        // Arange
        vm.prank(PLAYER);
        // Act
        vm.expectRevert(Raffle.Raffle__SendMoreEthToEnterRaffle.selector);
        raffle.enterRaffle();
        // Assert
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        // Assert
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        // Arrange
        vm.prank(PLAYER);

        // Act / Assert
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public playerEnteredRaffle {
        // Arrange
        raffle.performUpkeep("");

        // Act / Assert
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public playerEnteredRaffle {
        // Arrange
        raffle.performUpkeep("");

        // Assert
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
        assert(!upkeepNeeded);
    }

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public playerEnteredRaffle {
        // Arrange

        // Act / Assert
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState raffleState = raffle.getRaffleState();

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        currentBalance += entranceFee;
        numPlayers += 1;

        // Act
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, raffleState)
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestID() public playerEnteredRaffle {
        // Arrange

        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 requestID = logs[1].topics[1];

        // Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestID) > 0);
        assert(raffleState == Raffle.RaffleState.CALCULATING);
    }

    function testFullfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestID)
        public
        playerEnteredRaffle
    {
        // Arrange
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestID, address(raffle));
    }

    function testFullfillRandomWordsPicksWinnerResetsAndSendMoney() public playerEnteredRaffle {
        // Arrange
        uint256 additionalEntrants = 3;
        uint256 startingIndex = 1;
        address payable expectedWinner = payable(address(1));

        for (uint256 i = startingIndex; i <= additionalEntrants; i++) {
            address newPlayer = address(uint160(i));
            hoax(newPlayer, 10 ether);
            raffle.enterRaffle{value: entranceFee}();
        }
        uint256 winnerStartingBalance = expectedWinner.balance;
        uint256 startingTimeStamp = raffle.getLastTimeStamp();

        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 requestID = logs[1].topics[1];

        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestID), address(raffle));

        // Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = entranceFee * (additionalEntrants + 1);

        assertEq(recentWinner, expectedWinner);
        assertEq(uint256(raffleState), 0);
        assertEq(winnerBalance, winnerStartingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }
}
