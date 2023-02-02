// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IAsks {
    function createAsk(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _askPrice,
        address _askCurrency,
        uint96 _expiry
    )
        external;

    function updateAsk(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _askPrice,
        address _askCurrency,
        uint256 _expiry
    )
        external;

    function cancelAsk(address _tokenContract, uint256 _tokenId) external;

    function fillAsk(address _tokenContract, uint256 _tokenId, address _fillCurrency, uint256 _fillAmount)
        external
        payable;

    function fillAskWithPermit(
        address _tokenContract,
        uint256 _tokenId,
        address _fillCurrency,
        uint256 _fillAmount,
        uint256 _deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;

    /// @notice The metadata for an ask
    /// @param seller The address of the seller placing the ask
    /// @param askCurrency The address of the ERC-20, or address(0) for ETH, required to fill the ask
    /// @param askPrice The price to fill the ask
    struct Ask {
        address seller;
        address askCurrency;
        uint96 expiry;
        uint256 askPrice;
    }

    /// @notice Emitted when an ask is created
    /// @param tokenContract The ERC-721 token address of the created ask
    /// @param tokenId The ERC-721 token ID of the created ask
    /// @param ask The metadata of the created ask
    event AskCreated(address indexed tokenContract, uint256 indexed tokenId, Ask ask);

    /// @notice Emitted when an ask price is updated
    /// @param tokenContract The ERC-721 token address of the updated ask
    /// @param tokenId The ERC-721 token ID of the updated ask
    /// @param ask The metadata of the updated ask
    event AskUpdated(address indexed tokenContract, uint256 indexed tokenId, Ask ask);

    /// @notice Emitted when an ask is canceled
    /// @param tokenContract The ERC-721 token address of the canceled ask
    /// @param tokenId The ERC-721 token ID of the canceled ask
    /// @param ask The metadata of the canceled ask
    event AskCancelled(address indexed tokenContract, uint256 indexed tokenId, Ask ask);

    /// @notice Emitted when an ask is filled
    /// @param tokenContract The ERC-721 token address of the filled ask
    /// @param tokenId The ERC-721 token ID of the filled ask
    /// @param buyer The buyer address of the filled ask
    /// @param ask The metadata of the filled ask
    event AskFilled(address indexed tokenContract, uint256 indexed tokenId, address indexed buyer, Ask ask);

    /// @notice Emitted when currencyManager is changed
    event NewCurrencyManager(address currencyManager);

    /// @notice Emitted when collectionManager is changed
    event NewCollectionManager(address collectionManager);

    /// @notice Emitted when protocolFeeRecipient is changed
    event NewProtocolFee(address protocolFeeRecipient, uint256 fee);

    /// @notice Emitted when royaltyFeeManager is changed
    event NewRoyaltyFeeManager(address royaltyFeeManager);

    /// @notice Emitted when erc721TransferHelper is changed
    event NewERC721TransferHelper(address erc721TransferHelper);

    /// @notice Emitted when royalties are paid
    /// @param tokenContract The ERC-721 token address of the royalty payout
    /// @param tokenId The ERC-721 token ID of the royalty payout
    /// @param recipient The recipient address of the royalty
    /// @param currency The currency address of the royalty
    /// @param amount The amount paid to the recipient
    event RoyaltyPayout(
        address indexed tokenContract, uint256 indexed tokenId, address recipient, address currency, uint256 amount
    );
}
