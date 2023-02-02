// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./NeowizERC721.sol";

contract ChainLinkNeowizERC721 is VRFConsumerBaseV2, NeowizERC721 {
    uint64 public subscriptionId;
    VRFCoordinatorV2Interface public COORDINATOR;

    /// @param _name The name of the token
    /// @param _symbol The symbol of the token
    /// @param _maxTotalSupply The max token amount allowed to mint regardless of how many tokens are burnt.
    /// @param _teamSupply The token amount reserved for team
    /// @param _team The address to receive tokens in team-minting
    /// @param _payment The address of token to pay when minting. Set zero to use ETH.
    /// @param _unrevealedURI The ipfs uri of metadata before reveal
    /// @param _trustedForwarder The address of ERC2771 forwarder
    /// @param _subscriptionId Your chainlink subscriptionId. Constants from https://docs.chain.link/docs/vrf-contracts/
    /// @param _vrfCoordinator Chainlink vrfCoordinator in the network. See https://docs.chain.link/docs/vrf-contracts/#configurations
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxTotalSupply,
        uint256 _teamSupply,
        address _team,
        address _payment,
        string memory _unrevealedURI,
        address _trustedForwarder,
        uint64 _subscriptionId,
        address _vrfCoordinator
    )
        VRFConsumerBaseV2(_vrfCoordinator)
        NeowizERC721(_name, _symbol, _maxTotalSupply, _teamSupply, _team, _payment, _unrevealedURI, _trustedForwarder)
    {
        subscriptionId = _subscriptionId;
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    }

    /// @notice Request random number through Chainlink VRF
    /// @param _keyHash Chainlink-provided Key Hash
    /// @param _requestConfirmations Variable number of confirmations
    /// @param _callbackGasLimit Callback function gas limit
    function requestRandomSeed(
        bytes32 _keyHash,
        uint16 _requestConfirmations, // 3
        uint32 _callbackGasLimit // 100000
    )
        external
        whenSoldout
        onlyOwner
    {
        COORDINATOR.requestRandomWords(
            _keyHash,
            subscriptionId,
            _requestConfirmations,
            _callbackGasLimit,
            1 // numWords
        );
    }

    function fulfillRandomWords(uint256, /* requestId */ uint256[] memory _randomWords) internal override {
        _setRandomSeed(_randomWords[0]);
    }
}
