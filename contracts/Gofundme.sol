// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function transfer(address, uint) external returns (bool);

    function transferFrom(
        address,
        address,
        uint
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract Gofundme {
    // Events
    event lunch(address creator, uint amount, uint256 pledged, string decs, bool claimed);
    event donate(address sender, uint256 amt);
    event claim(address creator, uint256 id, uint256 amt);

    struct Campaign {
        address creator;
        uint256 amount;
        uint256 pledged;
        string description;
        bool claimed;
    }

    Campaign[] public campaigns;

    uint256 count;

    IERC20 public immutable token;

    // Add the address of the ERC20 token
    constructor(address _token) {
        token = IERC20(_token);
    }

    function createCampaingn(uint256 _amt, string memory _desc) public {
        count = count + 1;
        campaigns.push(Campaign(msg.sender, _amt, 0, _desc, false));

        emit lunch(msg.sender, _amt, 0, _desc, false);
    }

    function getCampaign(uint _id) public view returns(
        address, 
        uint256, 
        uint256, 
        string memory, 
        bool
        ) {
        Campaign storage campaign = campaigns[_id];
        return (
            campaign.creator, 
            campaign.amount, 
            campaign.pledged, 
            campaign.description, 
            campaign.claimed
            );
    }

    function totalCampaigns() public view returns(uint256) {
        return count;
    }

    error campaignNotAvailable (uint requested, uint total);

    function donateToCampaign(uint256 _id, uint256 _amt) public payable{
        Campaign storage campaign = campaigns[_id];
        require(token.balanceOf(msg.sender) > 0, "You have insufficient balance");
        require(campaign.pledged < campaign.amount, "Goal achieved");

        if(_id > count){
            revert campaignNotAvailable({
                requested: _id,
                total: count
            });
        }

        token.transferFrom(msg.sender, address(this), _amt);
        campaign.pledged += _amt;

        emit donate (msg.sender, _amt);

    }

    function claimPledges(uint256 _id) public payable {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "You can't withdraw this funds");
        require(campaign.pledged >= campaign.amount, "campign goal not reached");
        require(!campaign.claimed, "You have already claimed the pledges");

        token.transfer(msg.sender, campaign.pledged);
        campaign.claimed = true;

        delete campaigns;

        emit claim(msg.sender, _id, campaign.pledged);
    }
}