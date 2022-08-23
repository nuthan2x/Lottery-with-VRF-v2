// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract lottery_VRF_v2 is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // Goerli coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords =  2;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;

    address public manager;
    address payable[] public players;
    address payable lucky1;

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
      COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
      s_owner = msg.sender;
      s_subscriptionId = subscriptionId;
      manager  = msg.sender;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() external onlyOwner {
      // Will revert if subscription is not set and funded.
      s_requestId = COORDINATOR.requestRandomWords(
        keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
      );
    }

    function fulfillRandomWords(
      uint256, /* requestId */
      uint256[] memory randomWords
    ) internal override {
      s_randomWords = randomWords;
    }

  

    modifier onlyOwner() {
      require(msg.sender == s_owner);
      _;
    }

    
    // declaring the receive() function that is necessary to receive ETH
    receive() external payable{
        require(msg.value == 0.1 ether);
        require (msg.sender != manager);
        players.push(payable(msg.sender));
    }

    modifier onlyowner(){
        require(msg.sender == manager,"You cant call this function, only owner can.");
        _;
    }

      
    function getbalance() view public onlyowner returns(uint){
        
        return address(this).balance;
        
    }



    // helper function that returns a big random integer 
    // function random() view public returns(uint){
    //     return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length,msg.sender)));
    // }

    // selecting the winner
    function winner()   public  {
        uint r = s_randomWords[0] % players.length ;
        address payable lucky = players[r];

        lucky1 = lucky;
          
    }

    function release() public view returns(address payable){
        return lucky1;
    }

    
    // maager approving the pool total to the winner
    function settle() public onlyowner {
        require(players.length >= 2);
        uint  fee = getbalance() * 10/100 ;  // 10% fee for contract caller
        payable(manager).transfer(fee);
        
    
        lucky1.transfer(getbalance()); 
        players = new address payable[](0); 
    }
}

