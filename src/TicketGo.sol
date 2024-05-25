pragma solidity ^0.8.25;

import {AggregatorV3Interface} from "@chainlink/contracts@1.1.0/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TicketGo is Ownable VRFConsumerBaseV2{
    AggregatorV3Interface internal dataFeed;
    
    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    address public _operator;
    uint256 private concertId;
    mapping(uint256 => Concert) concertList;
    mapping(address => BuyerInfo[]) audiencePurchaseInfo;
    struct Concert {
        address concertOwner;
        string concertName;
        string singerName;
        uint256 startSaleTime;
        uint256 endSaleTime;
        Area[] areas;
    }

    struct Area {
        string areaName;
        uint256 seats;
        uint256 price;
    }

    struct BuyerInfo {
        uint256 concertId;
        string credential;
        string areaName;
        uint256 amount;
    }

    struct Audience {
        address audienceAddress;
        string credential; // user credential
        // mapping(uint256=>uint256) amountOfEachLevel; // level=>amount
        string areaName;
        uint256 amount;
    }

    event EventAddConctract(uint256 indexed concertId, Concert conert);
    event EventAudienceBuyInfo(address indexed audienceAddress, BuyerInfo buyerInfo);
    event EventConcertBought(
        uint256 indexed concertId,
        string indexed areaName,
        address audienceAddress
    );

    event EventAudienceCanceled(address indexed audienceAddress, BuyerInfo buyerInfo);
    event EvenetConcertCancelBought(uint256 indexed concertId,
        string indexed areaName,
        address audienceAddress);
    event AreaBookingSelected(uint256 indexed concerId, string concertName, uint256[] selectedBookingAddress);
    event ConcertSelected(uint256 indexed concerId);

    /**
     * Network: Sepolia
     * Aggregator: ETH/USD
     * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
     */
    // todo check how to contruct with multiple Inheritance
    constructor(address vrfCoordinatorV2) Ownable(msg.sender) VRFConsumerBaseV2(vrfCoordinatorV2){
        dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
    }

    function concertOf(uint256 _concertId)
        public
        view
        returns (Concert memory)
    {
        return concertList[_concertId];
    }

    function addConcert(
        string memory _concertName,
        string memory _singerName,
        uint256 _startSaleTime,
        uint256 _endSaleTime,
        Area[] memory _areas
    ) external {
        require(bytes(_concertName).length != 0, "conertName can not be null");
        require(bytes(_singerName).length != 0, "singerName can not be null");
        require(
            _endSaleTime >= _startSaleTime,
            "endSaleTime must be greate than startSaleTime"
        );
        uint256 currentConcertId = useConcertId();
        Concert storage currentConcert = concertList[currentConcertId];
        currentConcert.concertOwner = msg.sender;
        currentConcert.concertName = _concertName;
        currentConcert.singerName = _singerName;
        currentConcert.startSaleTime = _startSaleTime;
        currentConcert.endSaleTime = _endSaleTime;
        for (uint256 i = 0; i < _areas.length; i++) {
            currentConcert.areas.push(_areas[i]);
        }
        emit EventAddConctract(currentConcertId, currentConcert);
    }

    function useConcertId() internal returns (uint256) {
        return concertId++;
    }

    // function alterIsOnSale(uint256 _concertId) external onlyOwner {
    //     isOnSale[_concertId] = true;
    // }

    function isExistAreaName(uint256 _concertId, string memory _areaName)
        internal
        view
        returns (bool, uint256)
    {
        Concert storage concert = concertList[_concertId];
        Area[] storage areas = concert.areas;
        uint256 areaIndex;
        bool isExist = false;
        for (uint256 i = 0; i < areas.length; i++) {
            if (
                keccak256(abi.encode(areas[i].areaName)) ==
                keccak256(abi.encode(_areaName))
            ) {
                isExist = true;
                areaIndex = i;
            }
        }
        return (isExist, areaIndex);
    }

    /**
     * @dev The user calls this function to paurchase tickets.
     */
    function buy(
        uint256 _concertId,
        string memory _credential,
        string memory _areaName
    ) external payable {
        require(
            concertList[_concertId].startSaleTime <= block.timestamp,
            "Sale not start"
        );
        require(
            block.timestamp <= concertList[_concertId].endSaleTime,
            "Sale ends"
        );
        (bool isExist, uint256 areaIndex) = isExistAreaName(
            _concertId,
            _areaName
        );
        require(isExist, "Area dosen't exist");
        require(
            concertList[concertId].areas[areaIndex].price <=
                (msg.value * uint256(getChainlinkDataFeedLatestAnswer())) / 1e8,
            "Not Enough Amount"
        );
        (bool isBought, ) = isPurchase(_concertId, _credential, _areaName);
        require(!isBought, "You already bought");
        BuyerInfo memory buyerinfo = BuyerInfo({
            concertId: _concertId,
            credential: _credential,
            areaName: _areaName,
            amount: msg.value
        });
        audiencePurchaseInfo[msg.sender].push(buyerinfo);
        emit EventAudienceBuyInfo(msg.sender, buyerinfo);
        emit EventConcertBought(_concertId, _areaName, msg.sender);
    }

    function cancelBuy(
        uint256 _concertId,
        string memory _credential,
        string memory _areaName
    ) external {
        require(
            concertList[_concertId].startSaleTime <= block.timestamp,
            "Sale not start"
        );
        require(
            block.timestamp <= concertList[_concertId].endSaleTime,
            "Sale ends"
        );
        (bool isBought, uint256 boughtIndex) = isPurchase(_concertId, _credential, _areaName);
        require(isBought,"You have not bought");
        emit EventAudienceCanceled(msg.sender, audiencePurchaseInfo[msg.sender][boughtIndex]);
        deleteAudiencePurchaseInfo(boughtIndex);
        emit EvenetConcertCancelBought(_concertId, _areaName, msg.sender);
    }

    function isPurchase(
        uint256 _concertId,
        string memory _credential,
        string memory _areaName
    ) internal view returns (bool,uint256) {
        BuyerInfo[] memory buyerinfos = audiencePurchaseInfo[msg.sender];
        uint256 boughtIndex;
        bool isBought;
        for (uint256 i = 0; i < buyerinfos.length; i++) {
            if (
                buyerinfos[i].concertId == _concertId &&
                keccak256(abi.encodePacked(buyerinfos[i].areaName)) ==
                keccak256(abi.encodePacked(_areaName)) &&
                keccak256(abi.encodePacked(buyerinfos[i].credential)) ==
                keccak256(abi.encodePacked(_credential))
            ) {
                isBought = true;
                boughtIndex = i;
            }
        }
        return (isBought, boughtIndex);
    }

    function deleteAudiencePurchaseInfo(uint256 boughtIndex)internal {
        BuyerInfo storage buyerinfo = audiencePurchaseInfo[msg.sender][boughtIndex];
        uint256 buyerinfoLength = audiencePurchaseInfo[msg.sender].length;
        buyerinfo = audiencePurchaseInfo[msg.sender][buyerinfoLength-1];
        delete audiencePurchaseInfo[msg.sender][buyerinfoLength-1];
    }

    // this function should be call by Automation.
    // we can call it with a fixed Automation schedule, eg 00:00:00
    // so we choice the final luck user at fix datetime.
    // it's a tradeoff solution
    function autoTrigger(uint8 concertId) external{
        Concert concert = concertList[_concertId];
        uint8 randomWordsCount = concert.Area.length()

        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            randomWordsCount
        );
        emit RequestedConcertRandomWord(requestId);
    }

    /**
     * @dev This is the function that Chainlink VRF node
     * calls choice final booking.
     */
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        // s_players size 10
        // randomNumber 202
        // 202 % 10 ? what's doesn't divide evenly into 202?
        // 20 * 10 = 200
        // 2
        // 202 % 10 = 2


        mapping(concertID>mapping(string areaName>BuyerInfo[]) bookingMap
        // {
        //     "Area1": [{booking.userAddr}],
        //     "Area2": [{booking.userAddr}],
        //     "Area3": [{booking.userAddr}]

        // }
        for(uint i = 0; i < concert.Area.length; i++){
            areaRandomWord = randomWords[i]
            area = concert.Area[i]

            areaBookings = bookingMap[area.areaName]
            selectedAreaBookingIndexList = selectBookingForSingleArea(areaBookings, areaRandomWord)
            emit AreaBookingSelected{}
        }
        emit ConcertSelected{}
    } 

    function selectForSingleArea(avaiableNum uint256, seed uint256) returns(uint256[] selectedIdxList){
        uint256 seed = seed
        uint256 a=1664525
        uint256 c=1013904223
        uint256 m=2**32
        uint256[] memory selectedIdxList = new uint256[](avaiableNum)
        while (i < avaiableNum){
            idx = seed % avaiableNum
            selectedIdxList[i] = idx
            seed = (a * seed + c) % m
        }
    }
    
    // get leatest price ETH/USD
    function getChainlinkDataFeedLatestAnswer() public view returns (int256) {
        (
            ,
            /* uint80 roundID */
            int256 answer, /*uint startedAt*/ /*uint timeStamp*/
            ,
            ,

        ) = /*uint80 answeredInRound*/
            dataFeed.latestRoundData();
        return answer;
    }
}
