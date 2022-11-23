// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

contract CrowdFunding {
    // enum used to mark the campain after withdraw
    enum CampaignGoal {
        none,
        fully_funded,
        partially_funded
    }

    struct Campaign {
        string name;
        address owner;
        uint8 _campaignType;
        uint256 fundingGoal;
        uint256 totalFund;
        uint256 startTime;
        uint256 endTime;
        CampaignGoal _campaignGoal;
        bool isActive;
    }

    uint256 public campaignId;
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => bool)) public isFunded;
    mapping(uint256 => address[]) public FundersAddress;
    mapping(uint256 => mapping(address => uint256)) public totalUserFund;

    /**
     * @notice Emitted when new campaign added to the contract
     * @param _name Name of the campaign
     * @param _owner The address of the campaign owner
     * @param _campianType The type of the campaign 0 for startup or 1 for charity
     * @param _fundingGoal The number of fund the funding want to collect
     * @param totalFund The total number of fund funded to campaign
     * @param startTime The campaign start time
     * @param endTime The campaign end time
     * @param _campaignId The Id of the campaign
     */
    event NewCampaignAdded(
        string indexed _name,
        address indexed _owner,
        uint8 _campianType,
        uint256 _fundingGoal,
        uint256 totalFund,
        uint256 startTime,
        uint256 endTime,
        uint256 indexed _campaignId
    );

    /**
     * @notice Emitted when campaign Funded
     * @param _campaignId The Id of the campaign
     * @param funder The address of the funder
     * @param amount The number of ETH funded
     */
    event CampaignFunded(uint256 indexed _campaignId, address funder, uint256 amount);

    /**
     * @notice Emitted when the collected campaign fund withdrawn from the contract
     * @param _campaignID The Id of the campaign
     * @param totalFund The number of total fund collected
     */
    event CampaignFundWithdrawn(uint256 indexed _campaignID, uint256 totalFund);

    /**
     * @notice Emitted when the campaign cancelled
     * @param _campaignId The Id of the campaign
     * @param totalRefund The number of fund returned to the funders
     */
    event CampaignCancelled(uint256 indexed _campaignId, uint256 totalRefund);

    /**
     * @notice Emitted when Campaign marked as fully funder or partially funded
     * @param _camp Is type of campaign goal
     */
    event CampainMarked(CampaignGoal _camp);

    /**
     * @notice Functions marked with this modifier only called by the campaign owner
     * @param _campaignId The id of the campaign
     */
    modifier onlyOwner(uint256 _campaignId) {
        Campaign memory _campaign = campaigns[_campaignId];
        require(msg.sender == _campaign.owner, "Youre not campaign owner");
        _;
    }

    /**
     * @notice This modifier checks if the campaign is available or not
     * @param _campaignId The id of the campaign
     */
    modifier isCampaignAvailable(uint256 _campaignId) {
        require(_campaignId <= campaignId || _campaignId == 0, "campian not available");
        _;
    }

    /**
     * @notice This modifier checks if the campaign is active or not
     * @param _campaignId The id of the campaign
     */
    modifier isCampaignActive(uint256 _campaignId) {
        Campaign memory _campaign = campaigns[_campaignId];
        require(_campaign.isActive == true, "Campaign canceled");
        _;
    }

    /**
     * @notice Sets a new campaign and store on campaigns mapping by using campaignId as a key
     * @param _name campaign name
     * @param campianType The type of the campaign //Input 0 for startup 1 for charity
     * @param _fundingGoal The expected fund from the campaign
     * @param campaignDays The time campian is active to recieve funds
     */
    function setNewCampaign(string calldata _name, uint8 campianType, uint256 _fundingGoal, uint256 campaignDays)
        external
    {
        require(campaignDays <= 60, "only <= 60 days");
        require(campianType == 0 || campianType == 1, "0 for startup, 1 for charity");
        uint256 _endTime = block.timestamp + (campaignDays * 24 * 60 * 60);
        CampaignGoal _campaignGoal;
        campaignId++;
        campaigns[campaignId] =
            Campaign(_name, msg.sender, campianType, _fundingGoal, 0, block.timestamp, _endTime, _campaignGoal, true);

        emit NewCampaignAdded(
            _name, msg.sender, campianType, _fundingGoal, 0, block.timestamp, campaignDays, campaignId
            );
    }

    /**
     * @notice Funds an ether to campaign
     * @param _campaignId The unique Id of the campaign
     */
    function fundCampaign(uint256 _campaignId)
        external
        payable
        isCampaignAvailable(_campaignId)
        isCampaignActive(_campaignId)
    {
        require(msg.value > 0, "fund not 0");
        Campaign storage campaignToFund = campaigns[_campaignId];
        require(block.timestamp < campaignToFund.endTime, "This campaign already closed");
        campaignToFund.totalFund += msg.value;
        if (!isFunded[_campaignId][msg.sender]) {
            isFunded[_campaignId][msg.sender] = true;
            FundersAddress[_campaignId].push(msg.sender);
            totalUserFund[_campaignId][msg.sender] = msg.value;
        } else {
            totalUserFund[_campaignId][msg.sender] += msg.value;
        }
        emit CampaignFunded(_campaignId, msg.sender, msg.value);
    }

    /**
     * @notice Used to withdraw funds from the contract and marks campaign as fully funded or partially funded
     * @param _campaignId The unique Id of the campaign
     */
    function withdrawFund(uint256 _campaignId)
        external
        onlyOwner(_campaignId)
        isCampaignAvailable(_campaignId)
        isCampaignActive(_campaignId)
    {
        Campaign storage campaignToWithdraw = campaigns[_campaignId];
        require(campaignToWithdraw.endTime <= block.timestamp, "Funding period not finished");
        require(campaignToWithdraw.totalFund > 0, "There is no fund to withdraw");
        uint256 totalCampaignFund = campaignToWithdraw.totalFund;
        address campaignOwner = campaignToWithdraw.owner;
        uint256 _fundingGoal = campaignToWithdraw.fundingGoal;

        if (_fundingGoal > totalCampaignFund) {
            campaignToWithdraw._campaignGoal = CampaignGoal(2);
            emit CampainMarked(CampaignGoal(2));
        } else {
            campaignToWithdraw._campaignGoal = CampaignGoal(1);
            emit CampainMarked(CampaignGoal(1));
        }
        campaignToWithdraw.totalFund -= totalCampaignFund;
        payable(campaignOwner).transfer(totalCampaignFund); //change this with call
        assert(campaignToWithdraw.totalFund == 0);
        emit CampaignFundWithdrawn(_campaignId, totalCampaignFund);
    }

    /**
     * @notice Cancels the active campaign and returns funds to the funders
     * @param _campaignId The unique Id of the campaign
     */
    function cancelCampian(uint256 _campaignId) external onlyOwner(_campaignId) isCampaignAvailable(_campaignId) {
        Campaign storage campaignToCancel = campaigns[_campaignId];
        campaignToCancel.isActive = false;
        address[] memory campaignFunders = FundersAddress[_campaignId];

        for (uint256 i; i < campaignFunders.length; i++) {
            address userAddress = campaignFunders[i];
            uint256 userFund = totalUserFund[_campaignId][userAddress];
            campaignToCancel.totalFund -= userFund;
            payable(userAddress).transfer(userFund);
        }
        assert(campaignToCancel.totalFund == 0);
    }

    /**
     * @notice used to get the campaigns info
     * @param _campaignId The unique Id of the campaign
     */
    function getCampaign(uint256 _campaignId) external view returns (Campaign memory) {
        return campaigns[_campaignId];
    }

    /**
     * @notice Used to get Funders address for a particular campaign
     * @param _campaignId The unique Id of the campaign
     */
    function getFunders(uint256 _campaignId) public view returns (address[] memory) {
        return FundersAddress[_campaignId];
    }

    /**
     * @notice Used to get total campaign fund for a particular campaign
     * @param _campaignId The unique Id of the campaign
     */
    function getTotalCampianFund(uint256 _campaignId) public view returns (uint256) {
        return campaigns[_campaignId].totalFund;
    }

    /**
     * @notice Used to get the campaign owner
     * @param _campaignId The unique Id of the campaign
     */
    function getCampaignOwner(uint256 _campaignId) public view returns (address) {
        return campaigns[_campaignId].owner;
    }
}
