// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface INeowizERC721 {
    event PaymentUpdated(address payment);

    event UnrevealedURIUpdated(string uri);

    event RoundAdded(
        uint256 indexed roundId,
        uint256 state,
        uint256 maxMintPerAccount,
        uint256 maxMint,
        uint256 price,
        bytes32 merkleRoot,
        uint256 startTs,
        uint256 endTs
    );

    event StateUpdated(uint256 indexed roundId, uint256 state);

    event MaxMintUpdated(uint256 indexed roundId, uint256 maxMint);

    event MaxMintPerAccountUpdated(uint256 indexed roundId, uint256 maxMint);

    event PriceUpdated(uint256 indexed roundId, uint256 price);

    event MerkleRootUpdated(uint256 indexed roundId, bytes32 merkleRoot);

    event RoundTimestampUpdated(uint256 indexed roundId, uint256 startTs, uint256 endTs);

    event BaseURIUpdated(string uri);

    event RoyaltyInfoUpdated(address receiver, uint96 feeBasisPoints);

    event Revealed();

    function isRevealed() external returns (bool);
    function burn(uint256 _tokenId) external;
}
