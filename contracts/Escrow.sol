// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;


contract Escrow{
    error DisagreementError(string msg);
    address arbiter;
    mapping(address => Party) partiesMap;
    address[] parties;
    uint256 partiesLength;
    uint256 public pot;

    constructor(){
        arbiter = msg.sender;
    }

    struct Party{
        PartyType partyType;
        AgreementState agreementState;
    }

    enum PartyType{
        Payer,
        Payee
    }

    enum AgreementState{
        None,
        Agreed,
        Disagreed
    }

    modifier isPotEmpty{
        require(pot == 0, "Pot is not empty");
        _;
    }

    function getPartyByAddres(address _party) public view returns(Party memory){
        return partiesMap[_party];
    }

    function getParties() public view returns(address[] memory){
        return parties;
    }


    function getPartyType(PartyType partyType) public view returns(address){
        address user;
        for(uint i = 0; i < parties.length; i++){
            if(partiesMap[parties[i]].partyType == partyType){
                user = parties[i];
                break;
            }
        }

        return user;
    }

    function deposit(address payee) public isPotEmpty payable {
        // add depositer and payee to the list of parties
        partiesMap[msg.sender] = Party(PartyType.Payer, AgreementState.None);
        partiesMap[payee] = Party(PartyType.Payee, AgreementState.None);

        parties.push(msg.sender);
        parties.push(payee);

        partiesLength += 2;

        pot = msg.value;
    }
    function confirm() public{
        partiesMap[msg.sender].agreementState = AgreementState.Agreed;
    }
    function dispute() public{
        partiesMap[msg.sender].agreementState = AgreementState.Disagreed;
    }
    function release() public{
        require(msg.sender == arbiter, "Only the arbiter can release funds");
        uint approvals;
        for(uint i = 0; i < parties.length; i++){
            if(partiesMap[parties[i]].agreementState == AgreementState.Agreed){
                approvals++;
            }
        }

        if(approvals == parties.length){
            transfer(PartyType.Payee);
        }else{
            revert DisagreementError("There is a disagreement or neither parties has made any decisons yet hence funds cannot be released");
        }

    }

    function refund() public{
        uint disapprovals;
        for(uint i = 0; i < parties.length; i++){
            if(partiesMap[parties[i]].agreementState == AgreementState.Disagreed){
                disapprovals++;
            }
        }

        if(disapprovals > 0){
            transfer(PartyType.Payer);
        }else{
            revert DisagreementError("You cannot before a refund");
        }
    }

    function transfer(PartyType partyType) private{
        address user = getPartyType(partyType);

        uint256 potValue = pot;
        pot = 0;

        payable(user).transfer(potValue);
    }
}