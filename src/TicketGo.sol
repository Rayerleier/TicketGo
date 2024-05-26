// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AggregatorV3Interface} from "@chainlink/contracts@1.1.0/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./NFT.sol";

contract TicketGo is Ownable, VRFConsumerBaseV2, AutomationCompatibleInterface {
    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    AggregatorV3Interface internal _dataFeed;

    address private _operator;
    address public immutable nftToken;
    uint8 private withdrawPercent = 9;
    uint256 public concertId;

    mapping(uint256 => Concert) public concertList;
    mapping(address => BuyerInfo[]) public audiencePurchaseInfo;
    uint256 internal immutable _a = 1664525;
    uint256 internal immutable _c = 1013904223;
    uint256 internal immutable _m = 2 ** 32;

    mapping(uint256 => mapping(string => BuyerInfo[])) bookingPool;
    mapping(uint256 => mapping(string => mapping(address => uint256)))
        internal bookingAreaPoolIndex;
    mapping(uint256 => uint256) internal vrfRequestParamMap;

    struct Concert {
        uint256 concertId;
        address concertOwner;
        string concertName;
        string singerName;
        uint256 startSaleTime;
        uint256 endSaleTime;
        uint256 showTime;
        uint256 totalBalance;
        Area[] areas;
        bool withdrawed;
    }

    struct Area {
        string areaName;
        uint256 seats;
        uint256 price;
    }

    struct BuyerInfo {
        address audienceAddress;
        uint256 concertId;
        string credential;
        string areaName;
        uint256 amount;
        bool winning;
    }

    event EventAddConcert(uint256 indexed concertId, Concert concert);
    event EventAudienceBuyInfo(
        address indexed audienceAddress,
        BuyerInfo buyerInfo
    );
    event EventConcertBought(
        uint256 indexed concertId,
        string indexed areaName,
        address audienceAddress
    );
    event EventAudienceCanceled(
        address indexed audienceAddress,
        BuyerInfo buyerInfo
    );
    event AreaBookingSelected(
        uint256 indexed concertId,
        string concertName,
        uint256[] selectedBookingAddress
    );
    event ConcertSelected(uint256 indexed concertId);
    event EventConcertCancelBought(
        uint256 indexed concertId,
        string indexed areaName,
        address audienceAddress
    );
    event EventDispense(address indexed audienceAddress, BuyerInfo buyerInfo);
    event EventRefund(
        address indexed audienceAddress,
        bool isSuccessFul,
        BuyerInfo buyerInfo
    );
    event EventWithdraw(
        uint256 indexed concertId,
        bool singerSuccess,
        address singerAddress,
        uint256 singerAmount,
        bool operatorSuccess,
        address operatorAddress,
        uint256 operatorAmount
    );

    constructor(
        address vrfCoordinatorV2,
        address _nftToken
    ) Ownable(msg.sender) VRFConsumerBaseV2(vrfCoordinatorV2) {
        _operator = msg.sender;
        nftToken = _nftToken;
        _dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
    }

    function concertOf(
        uint256 _concertId
    ) public view returns (Concert memory) {
        return concertList[_concertId];
    }

    function addConcert(
        string memory _concertName,
        string memory _singerName,
        uint256 _startSaleTime,
        uint256 _endSaleTime,
        Area[] memory _areas
    ) external {
        require(bytes(_concertName).length != 0, "concertName cannot be null");
        require(bytes(_singerName).length != 0, "singerName cannot be null");
        require(
            _endSaleTime >= _startSaleTime,
            "endSaleTime must be greater than startSaleTime"
        );

        uint256 currentConcertId = _useConcertId();
        Concert storage currentConcert = concertList[currentConcertId];
        currentConcert.concertId = currentConcertId;
        currentConcert.concertOwner = msg.sender;
        currentConcert.concertName = _concertName;
        currentConcert.singerName = _singerName;
        currentConcert.startSaleTime = _startSaleTime;
        currentConcert.endSaleTime = _endSaleTime;
        for (uint256 i = 0; i < _areas.length; i++) {
            currentConcert.areas.push(_areas[i]);
        }
        emit EventAddConcert(currentConcertId, currentConcert);
    }

    function _useConcertId() internal returns (uint256) {
        return concertId++;
    }

    function _isExistAreaName(
        uint256 _concertId,
        string memory _areaName
    ) internal view returns (bool, uint256) {
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
        (bool isExist, uint256 areaIndex) = _isExistAreaName(
            _concertId,
            _areaName
        );
        require(isExist, "Area doesn't exist");
        require(
            concertList[_concertId].areas[areaIndex].price <=
                (msg.value * uint256(getChainlinkDataFeedLatestAnswer())) / 1e8,
            "Not Enough Amount"
        );
        (bool isBought, ) = _isPurchase(_concertId, _credential, _areaName);
        require(!isBought, "You already bought");
        BuyerInfo memory buyerInfo = BuyerInfo({
            audienceAddress: msg.sender,
            concertId: _concertId,
            credential: _credential,
            areaName: _areaName,
            amount: msg.value,
            winning: false
        });
        audiencePurchaseInfo[msg.sender].push(buyerInfo);
        _addBooking(buyerInfo);
        emit EventAudienceBuyInfo(msg.sender, buyerInfo);
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
        (bool isBought, uint256 boughtIndex) = _isPurchase(
            _concertId,
            _credential,
            _areaName
        );
        require(isBought, "You have not bought");
        emit EventAudienceCanceled(
            msg.sender,
            audiencePurchaseInfo[msg.sender][boughtIndex]
        );
        _deleteAudiencePurchaseInfo(boughtIndex);
        emit EventConcertCancelBought(_concertId, _areaName, msg.sender);
    }

    function _addBooking(BuyerInfo memory buyerInfo) internal {
        uint256 cid = buyerInfo.concertId;
        string memory aname = buyerInfo.areaName;
        bookingPool[cid][aname].push(buyerInfo);
        uint256 buyerAreaIndex = bookingPool[cid][aname].length - 1;
        bookingAreaPoolIndex[cid][aname][msg.sender] = buyerAreaIndex;
    }

    function _deleteBooking(BuyerInfo storage buyerInfo) internal {
        uint256 cid = buyerInfo.concertId;
        string memory aname = buyerInfo.areaName;
        uint256 buyerAreaIndex = bookingAreaPoolIndex[cid][aname][msg.sender];
        uint256 lastIndex = bookingPool[cid][aname].length - 1;
        bookingPool[cid][aname][buyerAreaIndex] = bookingPool[cid][aname][
            lastIndex
        ];
        bookingPool[cid][aname].pop();
        delete bookingAreaPoolIndex[cid][aname][msg.sender];
    }

    function _isPurchase(
        uint256 _concertId,
        string memory _credential,
        string memory _areaName
    ) internal view returns (bool, uint256) {
        BuyerInfo[] memory buyerInfos = audiencePurchaseInfo[msg.sender];
        uint256 boughtIndex;
        bool isBought;
        for (uint256 i = 0; i < buyerInfos.length; i++) {
            if (
                buyerInfos[i].concertId == _concertId &&
                keccak256(abi.encodePacked(buyerInfos[i].areaName)) ==
                keccak256(abi.encodePacked(_areaName)) &&
                keccak256(abi.encodePacked(buyerInfos[i].credential)) ==
                keccak256(abi.encodePacked(_credential))
            ) {
                isBought = true;
                boughtIndex = i;
            }
        }
        return (isBought, boughtIndex);
    }

    function _deleteAudiencePurchaseInfo(uint256 boughtIndex) internal {
        BuyerInfo storage buyerInfo = audiencePurchaseInfo[msg.sender][
            boughtIndex
        ];
        uint256 lastIndex = audiencePurchaseInfo[msg.sender].length - 1;
        if (boughtIndex != lastIndex) {
            audiencePurchaseInfo[msg.sender][
                boughtIndex
            ] = audiencePurchaseInfo[msg.sender][lastIndex];
        }
        audiencePurchaseInfo[msg.sender].pop();
        _deleteBooking(buyerInfo);
    }

    function dispense(BuyerInfo[] memory buyerList) public {
        for (uint256 i = 0; i < buyerList.length; i++) {
            TicketGoNFT(nftToken).mint(
                buyerList[i].audienceAddress,
                buyerList[i].concertId,
                buyerList[i].credential,
                buyerList[i].areaName
            );
            emit EventDispense(buyerList[i].audienceAddress, buyerList[i]);
        }
    }

    function singleRefund(BuyerInfo memory buyerInfo) public payable {
        uint256 refundAmount = buyerInfo.amount;
        buyerInfo.amount = 0;
        (bool success, ) = payable(buyerInfo.audienceAddress).call{
            value: refundAmount
        }("");
        emit EventRefund(buyerInfo.audienceAddress, success, buyerInfo);
    }

    function refund(BuyerInfo[] memory buyerList) public payable {
        for (uint256 i = 0; i < buyerList.length; i++) {
            singleRefund(buyerList[i]);
        }
    }

    function withdraw(uint256 _concertId) public payable onlyOwner {
        Concert memory concertInfo = concertOf(_concertId);
        address singerAddress = concertInfo.concertOwner;
        uint256 totalBalance = concertInfo.totalBalance;
        concertInfo.totalBalance = 0;
        uint256 singerAmount = (totalBalance * 90) / 100;
        uint256 operatorAmount = (totalBalance * 10) / 100;

        (bool singerSuccess, ) = payable(singerAddress).call{
            value: singerAmount
        }("");
        (bool operatorSuccess, ) = payable(_operator).call{
            value: operatorAmount
        }("");

        emit EventWithdraw(
            _concertId,
            singerSuccess,
            singerAddress,
            singerAmount,
            operatorSuccess,
            _operator,
            operatorAmount
        );
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        pure
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        return (true, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        checkBookPool();
    }

    function checkBookPool() internal {
        for (uint256 i = 0; i < concertId; i++) {
            Concert storage concert = concertList[i];
            if (
                concert.startSaleTime < block.timestamp &&
                concert.endSaleTime > block.timestamp
            ) {
                bookPoolSelect(concert);
            }
            bool singerWithdrawTimeCheck = concert.showTime + 3 >
                block.timestamp;
            bool singerWithdrawStatusCheck = concert.withdrawed == false;
            if (singerWithdrawTimeCheck && singerWithdrawStatusCheck) {
                withdraw(i);
            }
        }
    }

    function bookPoolSelect(Concert memory concert) internal {
        uint32 randomWordsCount = uint32(concert.areas.length);
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            randomWordsCount
        );
        vrfRequestParamMap[requestId] = concert.concertId;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 _concertId = vrfRequestParamMap[requestId];
        Concert storage concert = concertList[_concertId];
        (
            BuyerInfo[] memory fortuneBuys,
            BuyerInfo[] memory unfortuneBuys
        ) = drawConcert(concert, randomWords);
        processDrawResult(fortuneBuys, unfortuneBuys);
    }

    function processDrawResult(
        BuyerInfo[] memory fortuneBuys,
        BuyerInfo[] memory unfortuneBuys
    ) internal {
        dispense(fortuneBuys);
        refund(unfortuneBuys);
    }

    function drawConcert(
        Concert storage concert,
        uint256[] memory randomWords
    ) internal view returns (BuyerInfo[] memory, BuyerInfo[] memory) {
        BuyerInfo[] memory c_fortuneBuys;
        BuyerInfo[] memory c_unfortuneBuys;

        for (uint256 i = 0; i < concert.areas.length; i++) {
            uint256 randomWord = randomWords[i];
            Area memory area = concert.areas[i];
            BuyerInfo[] memory areaPool = bookingPool[concert.concertId][
                area.areaName
            ];
            (
                BuyerInfo[] memory fortuneBuys,
                BuyerInfo[] memory unfortuneBuys
            ) = drawForAreaPool(areaPool, area.seats, randomWord);
            c_fortuneBuys = mergeBuyerInfoArrays(c_fortuneBuys, fortuneBuys);
            c_unfortuneBuys = mergeBuyerInfoArrays(
                c_unfortuneBuys,
                unfortuneBuys
            );
        }

        return (c_fortuneBuys, c_unfortuneBuys);
    }

    function drawForAreaPool(
        BuyerInfo[] memory areaPool,
        uint256 availableNum,
        uint256 _seed
    ) internal pure returns (BuyerInfo[] memory, BuyerInfo[] memory) {
        BuyerInfo[] memory fortuneBuys = new BuyerInfo[](availableNum);
        BuyerInfo[] memory unfortuneBuys = new BuyerInfo[](
            areaPool.length - availableNum
        );
        uint256[] memory selectedIndexList = drawAreaPoolIndex(
            areaPool.length,
            availableNum,
            _seed
        );

        uint256 fortuneIndex = 0;
        uint256 unfortuneIndex = 0;

        for (uint256 areaIdx = 0; areaIdx < areaPool.length; areaIdx++) {
            bool selected = false;
            for (
                uint256 selectedIdx = 0;
                selectedIdx < selectedIndexList.length;
                selectedIdx++
            ) {
                if (areaIdx == selectedIndexList[selectedIdx]) {
                    selected = true;
                    break;
                }
            }
            if (selected) {
                fortuneBuys[fortuneIndex] = areaPool[areaIdx];
                fortuneIndex++;
            } else {
                unfortuneBuys[unfortuneIndex] = areaPool[areaIdx];
                unfortuneIndex++;
            }
        }
        return (fortuneBuys, unfortuneBuys);
    }

    function drawAreaPoolIndex(
        uint256 totalNum,
        uint256 availableNum,
        uint256 _seed
    ) internal pure returns (uint256[] memory) {
        uint256[] memory selectedIdxList = new uint256[](availableNum);
        uint256 seed = _seed;
        for (uint256 i = 0; i < availableNum; i++) {
            uint256 idx = seed % totalNum;
            selectedIdxList[i] = idx;
            seed = (_a * seed + _c) % _m;
        }
        return selectedIdxList;
    }

    function mergeBuyerInfoArrays(
        BuyerInfo[] memory a,
        BuyerInfo[] memory b
    ) internal pure returns (BuyerInfo[] memory) {
        BuyerInfo[] memory result = new BuyerInfo[](a.length + b.length);
        for (uint256 i = 0; i < a.length; i++) {
            result[i] = a[i];
        }
        for (uint256 j = 0; j < b.length; j++) {
            result[a.length + j] = b[j];
        }
        return result;
    }

    function getChainlinkDataFeedLatestAnswer() public view returns (int256) {
        (, int256 answer, , , ) = _dataFeed.latestRoundData();
        return answer;
    }
}
