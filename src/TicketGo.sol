// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AggregatorV3Interface} from "foundry-chainlink-toolkit/src/interfaces/feeds/AggregatorV3Interface.sol";

contract TicketGo {
    AggregatorV3Interface internal dataFeed;

    address public _operator;
    // address public _ticketProvider;
    Concert[] ConcertList;  
    mapping(uint256 conertId=>uint256 amount) balancesOfConcert;  // conertId=>
    uint256 private conertId;  // unique Id of conert
    mapping(uint256=>Concert) concertIdOf;  // query conert info using concertId
    struct Concert{
        address concertOwner;
        string concertName;
        string singerName;
        uint256 startSaleTime;
        uint256 endSaleTime;
        Area [] area;
    }

    struct Area{ 
        string areaName;
        uint256 seats; 
        uint256 price;
    }

    struct Audience {
        address audienceAddress;
        string credential;  // user credential
        uint256 concertId;
        uint256 amount;    
        uint256 ticketLeavel;  
    }

    address[] public activityPool;

    /**
     * Network: Sepolia
     * Aggregator: ETH/USD
     * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
     */
    constructor() {
        dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    // get leatest price ETH/USD
    function getChainlinkDataFeedLatestAnswer() public view returns (int256) {
        (
            /* uint80 roundID */
            ,
            int256 answer,
            /*uint startedAt*/
            ,
            /*uint timeStamp*/
            ,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }
}
