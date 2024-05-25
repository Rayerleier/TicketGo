pragma solidity ^0.8.25;

import {AggregatorV3Interface} from "@chainlink/contracts@1.1.0/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TicketGo is Ownable {
    AggregatorV3Interface internal dataFeed;

    address public _operator;
    uint256 private concertId;
    mapping(uint256 => Concert) concertList;
    mapping(uint256 => bool) isOnSale;
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
    event EventBuyerInfo(address indexed audienceAddress, BuyerInfo buyerInfo);
    event EventConcertBought(
        uint256 indexed concertId,
        string indexed areaName,
        address audienceAddress
    );

    /**
     * Network: Sepolia
     * Aggregator: ETH/USD
     * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
     */
    constructor() Ownable(msg.sender) {
        dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
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
        isOnSale[currentConcertId] = false;
        emit EventAddConctract(currentConcertId, currentConcert);
    }

    function useConcertId() internal returns (uint256) {
        return concertId++;
    }

    function alterIsOnSale(uint256 _concertId) external onlyOwner {
        isOnSale[_concertId] = true;
    }

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
        require(isOnSale[_concertId] == true, "this conert dose not on sale");
        (bool isExist, uint256 areaIndex) = isExistAreaName(
            _concertId,
            _areaName
        );
        require(isExist, "Area dosen't exist");
        require(
            concertList[concertId].areas[areaIndex].price <= msg.value*uint256(getChainlinkDataFeedLatestAnswer())/1e8,
            "Not Enough Amount"
        );

        BuyerInfo memory buyerinfo = BuyerInfo({
            concertId: _concertId,
            credential: _credential,
            areaName: _areaName,
            amount: msg.value
        });
        audiencePurchaseInfo[msg.sender].push(buyerinfo);
        emit EventBuyerInfo(msg.sender, buyerinfo);
        emit EventConcertBought(_concertId, _areaName, msg.sender);
    }

    function cancelBuy(
        uint256 _concertId,
        string memory _credential,
        string memory _areaName
    ) external {

    }

    // get leatest price ETH/USD
    function getChainlinkDataFeedLatestAnswer() public view returns (int256) {
        (
            ,
            /* uint80 roundID */
            int256 answer,
            ,
            ,

        ) = /*uint startedAt*/
            /*uint timeStamp*/
            /*uint80 answeredInRound*/
            dataFeed.latestRoundData();
        return answer;
    }
}
