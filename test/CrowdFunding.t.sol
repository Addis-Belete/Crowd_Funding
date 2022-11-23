// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "../lib/forge-std/src/test.sol";
import "../src/CrowdFunding.sol";

contract CrowdFundingTest is Test {
    CrowdFunding crowdfunding;

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
}
