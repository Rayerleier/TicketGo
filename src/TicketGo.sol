// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// import {AggregatorV3Interface} from "foundry-chainlink-toolkit/src/interfaces/feeds/AggregatorV3Interface.sol";

contract TicketGo {
    // AggregatorV3Interface internal dataFeed;

    address public _operator;
    // address public _ticketProvider;
    uint256 private concertId;
    mapping(uint256 concertId=> Concert) concertList; 
    mapping (uint256 concertId=> bool) isOnSale;
    struct Concert {
        address concertOwner;
        string concertName;
        string singerName;
        uint256 startSaleTime;
        uint256 endSaleTime;
        Area[] area;
    }

    struct Area {
        string areaName;
        uint256 seats;
        uint256 price;
    }

    struct Audience {
        address audienceAddress;
        string credential; // user credential
        // mapping(uint256=>uint256) amountOfEachLevel; // level=>amount
        uint256 level;
        uint256 amount;
    }

    event EventAddConctract(uint256 concertId, Concert conert);

    /**
     * Network: Sepolia
     * Aggregator: ETH/USD
     * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
     */
    constructor() {
        // dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    function addConcert(
        string memory _concertName,
        string memory _singerName,
        uint256 _startSaleTtime,
        uint256 _endSaleTime,
        Area[] memory _area
    ) external {

        require(bytes(_concertName).length!=0, "conertName can not be null");
        require(bytes(_singerName).length!=0, "singerName can not be null");
        require(_endSaleTime>=_startSaleTtime,"endSaleTime must be greate than startSaleTime");
        uint256 currentConcertId = useConcertId();
        Concert memory currentConcert = Concert({
            concertOwner: msg.sender,
            concertName: _concertName,
            singerName: _singerName,
            startSaleTime: _startSaleTtime,
            endSaleTime: _endSaleTime,
            area: _area
        });
        concertList[currentConcertId] = currentConcert;
        isOnSale[currentConcertId] = false;
        emit EventAddConctract(currentConcertId, currentConcert);
    }

    function useConcertId() internal returns (uint256) {
        return concertId++;
    }

    function concertOf(uint256 _concertId)
        public
        view
        returns (Concert memory)
    {
        return concertList[_concertId];
    }

    // // get leatest price ETH/USD
    // function getChainlinkDataFeedLatestAnswer() public view returns (int256) {
    //     (
    //         /* uint80 roundID */
    //         ,
    //         int256 answer,
    //         /*uint startedAt*/
    //         ,
    //         /*uint timeStamp*/
    //         ,
    //         /*uint80 answeredInRound*/
    //     ) = dataFeed.latestRoundData();
    //     return answer;
    // }
}
