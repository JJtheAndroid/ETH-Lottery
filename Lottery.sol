// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract Lottery is VRFConsumerBaseV2, ConfirmedOwner {

    receive() external payable{}

    event winner (address winner, uint amount);
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);


    uint timetopickwinner;


    //uint to track the last lotto prize
    uint lastlottocount;
    
    //array to track prize winnings 
    uint [] public prizes;

    //array to track past winners 
    address payable[] public lastwinners;
   
   

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    bytes32 keyHash =
        0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    
    uint32 callbackGasLimit = 100000;

    uint16 requestConfirmations = 3;

    
    uint32 numWords = 1;

    /**
     * HARDCODED FOR GOERLI
     * COORDINATOR: 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
     */
    constructor(
        uint64 subscriptionId
    )
        VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
        );
        s_subscriptionId = subscriptionId;

        timetopickwinner = block.timestamp + 10 minutes;

       
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords()
        internal
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

 

//this line creates an array of players that sent in ether 
address payable [] public players;



//this line return the overrall balance in the smart contract lottery 
function Getbalance () public view returns (uint) {
    return address(this).balance;
}

//this line returns the players in the lottery
function getPlayerslength () public view returns (address payable [] memory){
return players;
}

//this function returns the number of players in the lottery 
function GetnumPlayers () public view returns (uint){
    return players.length;
}

//this function adds the requirement for the lottery and pushes each entry into the players array
function enter () public payable {


    require(msg.value == 0.05 ether, "You have do not have enough ether");
    players.push(payable(msg.sender));
}





//this function uses the random number to pick a winner 
function pickWinner() public {
    require (block.timestamp >= timetopickwinner, "This lotto is not finished yet");
    requestRandomWords();
    prizes.push(address(this).balance);
    
    uint index = requestRandomWords() % players.length;
  (bool sent,) = players[index].call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");

    lastlottocount++;

    lastwinners.push(players[index]);
    

    
    

    emit winner (players[index], address(this).balance);
   
   
  //this line resets the lottery by resetting the array to 0
    timetopickwinner = block.timestamp + 10 minutes;
    players = new address payable [](0);

    
}

function returnlastprize () external view returns (uint){
return prizes[lastlottocount -1];

}

function returnlastwinner () external view returns (address payable) {
return lastwinners[lastlottocount -1];
}


function Timeleft () external view returns (uint){

    return timetopickwinner-block.timestamp;
}





}






