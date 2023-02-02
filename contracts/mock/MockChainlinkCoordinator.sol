// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract MockChainlinkCoordinator {
    function sendRandom(address _consumer, uint256 _requestId, uint256[] memory _randomWords) public {
        VRFConsumerBaseV2(_consumer).rawFulfillRandomWords(_requestId, _randomWords);
    }
}
