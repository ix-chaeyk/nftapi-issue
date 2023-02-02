// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./NeowizERC721.sol";

contract BlockhashNeowizERC721 is NeowizERC721 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxTotalSupply,
        uint256 _teamSupply,
        address _team,
        address _payment,
        string memory _unrevealedURI,
        address _trustedForwarder
    )
        NeowizERC721(_name, _symbol, _maxTotalSupply, _teamSupply, _team, _payment, _unrevealedURI, _trustedForwarder)
    {}

    function requestRandomSeed() external whenSoldout onlyOwner {
        _setRandomSeed(uint256(blockhash(block.number - 1)));
    }
}
