// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TicketGo} from "../src/TicketGo.sol";
import {TicketGoNFT} from "../src/NFT.sol";
import {VRFCoordinatorV2Mock} from "../src/VRFCoordinatorV2Mock.sol";
import "../src/interface/ITicketGo.sol";

contract TicketGoTest is Test, ITicketGo {
    VRFCoordinatorV2Mock vtfMock;
    TicketGo ticketgo;
    TicketGoNFT ticketGoNft;
    address singer1 = makeAddr("singer1");
    address singer2 = makeAddr("singer2");
    address singer3 = makeAddr("singer3");
    address buyer1 = makeAddr("buyer1");
    address buyer2 = makeAddr("buyer2");
    address buyer3 = makeAddr("buyer3");

    function setUp() public {
        ticketgo = new TicketGo(address(vtfMock), address(ticketGoNft));
        vm.deal(buyer1, 20 ether);
        vm.deal(buyer2, 20 ether);
        vm.deal(buyer3, 20 ether);
    }

    function testAddConcert() public {
        Area[] memory areas = new Area[](2);
        areas[0] = Area("VIP", 1, 1 ether);
        areas[1] = Area("General", 1, 0.5 ether);
        vm.prank(singer1);
        _addConcert(
            unicode"张杰演唱会",
            unicode"张杰",
            block.timestamp + 1 days,
            block.timestamp + 2 days,
            block.timestamp + 7 days,
            areas
        );
        assertEq(ticketgo.concertOf(0).concertName, unicode"张杰演唱会");
        assertEq(ticketgo.concertOf(0).concertOwner, address(singer1));

        Area[] memory nullArea;
        vm.startPrank(singer2);
        vm.expectRevert();
        _addConcert(
            unicode"邓紫棋演唱会",
            unicode"邓紫棋",
            block.timestamp + 1 days,
            block.timestamp,
            block.timestamp + 7 days,
            areas
        );
        vm.expectRevert();
        _addConcert(
            unicode"邓紫棋演唱会",
            unicode"邓紫棋",
            block.timestamp + 1 days,
            block.timestamp + 2 days,
            block.timestamp + 7 days,
            nullArea
        );
        vm.stopPrank();
    }

    // 添加一场音乐会
    function _addConcert(
        string memory _concertName,
        string memory _singerName,
        uint256 _startSaleTime,
        uint256 _endSaleTime,
        uint256 _showTime,
        Area[] memory _areas
    ) internal {
        ticketgo.addConcert(
            _concertName,
            _singerName,
            _startSaleTime,
            _endSaleTime,
            _showTime,
            _areas
        );
    }

    function testBuy() public {
        testAddConcert();
        vm.startPrank(buyer1);
        vm.expectRevert("Sale not start");
        _buy(0, "350122", "VIP");
        vm.warp(block.timestamp + 3 days);
        vm.expectRevert("Sale ends");
        _buy(0, "350122", "VIP");
        vm.warp(block.timestamp - 1.5 days);
        vm.expectRevert("Area doesn't exist");
        _buy(0, "350122", "NoneExisted");

        _buy(0, "350122", "VIP");
        vm.expectRevert("You already bought");
        _buy(0, "350122", "VIP");
        _buy(0, "350122", "General");
        BuyerInfo memory buyerInfo1 = ticketgo.audienceOf(buyer1)[0];
        vm.assertEq(buyerInfo1.areaName, "VIP");
        vm.assertEq(buyerInfo1.concertId, 0);
        vm.assertEq(buyerInfo1.credential, "350122");
        BuyerInfo memory buyerInfo2 = ticketgo.audienceOf(buyer1)[1];
        vm.assertEq(buyerInfo2.areaName, "General");
        vm.assertEq(buyerInfo2.concertId, 0);
        vm.assertEq(buyerInfo2.credential, "350122");
        vm.stopPrank();
        vm.startPrank(buyer2);
        vm.expectRevert();
        _buy(0, "350122", "VIP"); // 测试另一个人能不能再买入
        _buy(0, "350110", "VIP");
        _buy(0, "350110", "General");
        vm.stopPrank();
    }

    function _buy(
        uint256 _concertId,
        string memory _credential,
        string memory _areaName
    ) internal {
        // ticketgo.concertList[_concertId].;
        ticketgo.buy{value: 1 ether}(_concertId, _credential, _areaName);
    }

    function testCancelBuy() public {
        testBuy();
        vm.startPrank(buyer2);
        vm.expectRevert();
        _cancelBuy(0, "350122", "VIP");  //测试另一个人能不能帮别人取消
        vm.stopPrank();
        vm.startPrank(buyer1);
        _cancelBuy(0, "350122", "VIP");
        BuyerInfo memory buyerInfo1 = ticketgo.audienceOf(buyer1)[0];
        vm.assertEq(buyerInfo1.areaName, "General");
        vm.assertEq(buyerInfo1.concertId, 0);
        vm.assertEq(buyerInfo1.credential, "350122");
        vm.expectRevert();
        _cancelBuy(0, "350122", "VIP");
        _cancelBuy(0, "350122", "General");
        BuyerInfo memory buyerInfo2 = ticketgo.audienceOf(buyer1)[0];
        assertEq(buyerInfo2.credential, "");
        vm.stopPrank();
    }

    function _cancelBuy(
        uint256 _concertId,
        string memory _credential,
        string memory _areaName
    ) internal {
        ticketgo.cancelBuy(_concertId, _credential, _areaName);
    }




    function _fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords) internal{

    }
}
