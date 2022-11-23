// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "../lib/forge-std/src/test.sol";
import "../src/Crowdfunding.sol";

contract CounterTest is Test {
    CrowdFunding public crowdfunding;

    function setUp() public {
        crowdfunding = new CrowdFunding();
    }

    function testSetNewCampaign() public {
        uint256 fund = 10 ether;
        vm.startPrank(address(10));
        crowdfunding.setNewCampaign("Addis", 1, fund, 10);
        assertEq(crowdfunding.campaignId(), 1);
        vm.stopPrank();
    }

    function testFundCampaign() public {
        testSetNewCampaign();
        hoax(address(20));
        crowdfunding.fundCampaign{value: 2 ether}(1);
        vm.stopPrank();
        hoax(address(30));
        crowdfunding.fundCampaign{value: 2 ether}(1);
        vm.stopPrank();
    }

    function testFailFundCampaign() public {
        testSetNewCampaign();
        hoax(address(20));
        crowdfunding.fundCampaign{value: 2 ether}(2);
        vm.stopPrank();
        hoax(address(30));
        crowdfunding.fundCampaign{value: 2 ether}(2);
        vm.stopPrank();
    }

    function testFailFundCampaign1() public {
        testFundCampaign();
        hoax(address(50));
        uint256 time = 11 * 24 * 60 * 60;
        skip(time);
        crowdfunding.fundCampaign{value: 2 ether}(1);
        vm.stopPrank();
    }

    function testWithdrawFund() public {
        testFundCampaign();
        address owner = crowdfunding.getCampaignOwner(1);
        uint256 time = 11 * 24 * 60 * 60;
        vm.startPrank(owner);
        skip(time);
        crowdfunding.withdrawFund(1);
        uint256 totalFund = crowdfunding.getTotalCampianFund(1);
        console.log(totalFund);
        assertEq(totalFund, 0);
    }

    function testFailWithdrawFund() public {
        testFundCampaign();
        vm.startPrank(address(10));
        crowdfunding.withdrawFund(1);
    }

    function testFailWithdrawFund1() public {
        testFundCampaign();
        vm.startPrank(address(12));
        crowdfunding.withdrawFund(1);
    }

    function testCancelCampian() public {
        testFundCampaign();
        hoax(address(10));
        crowdfunding.cancelCampian(1);
        uint256 totalFund = crowdfunding.getTotalCampianFund(1);
        console.log("total campian fund after campaign canceled ", totalFund);
    }

    function testFailCancelCampaign() public {
        testFundCampaign();
        vm.startPrank(address(20));
        crowdfunding.cancelCampian(1);
    }
}
