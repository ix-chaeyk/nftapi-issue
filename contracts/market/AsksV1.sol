// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IAsks.sol";
import "./interfaces/IRoyaltyFeeManager.sol";
import "./interfaces/ICurrencyManager.sol";
import "./interfaces/ICollectionManager.sol";
import "../lib/metatx/ERC2771ContextFromStorage.sol";
import "./lib/IncomingTransferSupportV1.sol";
import "./lib/OutgoingTransferSupportV1.sol";
import "./lib/transferHelpers/ERC721TransferHelper.sol";
import "./lib/UniversalExchangeEventV1.sol";

// import '../../lib/forge-std/src/console.sol';

contract AsksV1 is
    IAsks,
    Ownable,
    ReentrancyGuard,
    ERC2771ContextFromStorage,
    UniversalExchangeEventV1,
    IncomingTransferSupportV1,
    OutgoingTransferSupportV1
{
    /// @dev The indicator to pass all remaining gas when paying out royalties
    uint256 private constant USE_ALL_GAS_FLAG = 0;

    /// @notice The ask for a given NFT, if one exists
    /// @dev ERC-721 token contract => ERC-721 token ID => Ask
    mapping(address => mapping(uint256 => Ask)) public askForNFT;

    uint256 public fee;

    address public protocolFeeRecipient;

    IRoyaltyFeeManager public royaltyFeeManager;

    ICurrencyManager public currencyManager;

    ICollectionManager public collectionManager;

    ERC721TransferHelper public erc721TransferHelper;

    /**
     * @param _fee decimal 4. Override _feeDenominator() to change.
     * @param _trustedForwarder an argument for ERC2771Context
     */
    constructor(
        uint256 _fee,
        address _protocolFeeRecipient,
        address _erc20TransferHelper,
        address _erc721TransferHelper,
        address _royaltyFeeManager,
        address _currencyManager,
        address _collectionManager,
        address _trustedForwarder,
        address _wethAddress
    )
        ERC2771ContextFromStorage(_trustedForwarder)
        IncomingTransferSupportV1(_erc20TransferHelper)
        OutgoingTransferSupportV1(_wethAddress)
    {
        fee = _fee;
        protocolFeeRecipient = _protocolFeeRecipient;
        royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
        currencyManager = ICurrencyManager(_currencyManager);
        collectionManager = ICollectionManager(_collectionManager);
        erc721TransferHelper = ERC721TransferHelper(_erc721TransferHelper);
    }

    /// @notice Creates the ask for a given NFT
    function createAsk(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _askPrice,
        address _askCurrency,
        uint96 _expiry
    )
        external
        override
        nonReentrant
    {
        address tokenOwner = IERC721(_tokenContract).ownerOf(_tokenId);

        require(_askPrice > 0, "createAsk askPrice should be bigger than 0");
        require(
            _msgSender() == tokenOwner || IERC721(_tokenContract).isApprovedForAll(tokenOwner, _msgSender()),
            "createAsk must be token owner or operator"
        );
        require(erc721TransferHelper.isModuleRegistered(), "createAsk must approve AsksV1 module");
        require(
            IERC721(_tokenContract).isApprovedForAll(tokenOwner, address(erc721TransferHelper)),
            "createAsk must approve ERC721TransferHelper as operator"
        );
        // Verify whether the currency is whitelisted
        require(currencyManager.isCurrencyWhitelisted(_askCurrency), "createAsk currency must be whitelisted");
        require(collectionManager.isTokenWhitelisted(_tokenContract), "createAsk tokenContract must be whitelisted");

        if (askForNFT[_tokenContract][_tokenId].seller != address(0)) {
            _cancelAsk(_tokenContract, _tokenId);
        }

        askForNFT[_tokenContract][_tokenId] =
            Ask({seller: tokenOwner, askCurrency: _askCurrency, askPrice: _askPrice, expiry: _expiry});

        emit AskCreated(_tokenContract, _tokenId, askForNFT[_tokenContract][_tokenId]);
    }

    /// @notice Updates the ask price for a given NFT
    function updateAsk(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _askPrice,
        address _askCurrency,
        uint256 _expiry
    )
        external
        override
        nonReentrant
    {
        Ask storage ask = askForNFT[_tokenContract][_tokenId];

        require(ask.seller == _msgSender(), "setAskPrice must be seller");
        ask.askPrice = _askPrice;
        ask.askCurrency = _askCurrency;
        ask.expiry = uint96(_expiry);

        emit AskUpdated(_tokenContract, _tokenId, ask);
    }

    /// @notice Cancel the ask for a given NFT
    function cancelAsk(address _tokenContract, uint256 _tokenId) external nonReentrant {
        require(askForNFT[_tokenContract][_tokenId].seller != address(0), "cancelAsk ask doesn't exist");

        address tokenOwner = IERC721(_tokenContract).ownerOf(_tokenId);
        require(
            _msgSender() == tokenOwner || IERC721(_tokenContract).isApprovedForAll(tokenOwner, _msgSender()),
            "cancelAsk must be token owner or operator"
        );

        _cancelAsk(_tokenContract, _tokenId);
    }

    /// @notice
    // handle incoming payment (eth or erc20)
    // transfer royalty
    // transfer protocol fee
    // transfer the rest to the seller
    // ERC721 transfer to the buyer
    // emit Event
    // delete from the storage
    function fillAsk(address _tokenContract, uint256 _tokenId, address _fillCurrency, uint256 _fillAmount)
        external
        payable
        override
        nonReentrant
    {
        _validateAsk(_tokenContract, _tokenId, _fillCurrency, _fillAmount);
        _fillAsk(_tokenContract, _tokenId);
    }

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
        external
        override
        nonReentrant
    {
        _validateAsk(_tokenContract, _tokenId, _fillCurrency, _fillAmount);
        IERC20Permit(_fillCurrency).permit(_msgSender(), address(erc20TransferHelper), _fillAmount, _deadline, v, r, s);
        _fillAsk(_tokenContract, _tokenId);
    }

    function setTrustedForwarder(address _forwarder) external onlyOwner {
        _trustedForwarder = _forwarder;
        emit NewTrustedForwarder(_forwarder);
    }

    function updateERC721TransferHelper(address _erc721TransferHelper) external onlyOwner {
        erc721TransferHelper = ERC721TransferHelper(_erc721TransferHelper);
        emit NewERC721TransferHelper(_erc721TransferHelper);
    }

    /**
     * @notice Update currency manager
     * @param _currencyManager new currency manager
     */
    function updateCurrencyManager(address _currencyManager) external onlyOwner {
        currencyManager = ICurrencyManager(_currencyManager);
        emit NewCurrencyManager(_currencyManager);
    }

    /**
     * @notice Update token whitelist manager
     * @param _collectionManager new token whitelist manager
     */
    function updateCollectionManager(address _collectionManager) external onlyOwner {
        collectionManager = ICollectionManager(_collectionManager);
        emit NewCollectionManager(_collectionManager);
    }

    /**
     * @notice Update protocol fee recipient
     * @param _protocolFeeRecipient new recipient for protocol fees
     * @param _fee new protocol fee. decimal is determined by  `_feeDenominator()`
     */
    function updateProtocolFee(address _protocolFeeRecipient, uint256 _fee) external onlyOwner {
        protocolFeeRecipient = _protocolFeeRecipient;
        fee = _fee;
        emit NewProtocolFee(_protocolFeeRecipient, _fee);
    }

    /**
     * @notice Update royalty fee manager
     * @param _royaltyFeeManager new fee manager address
     */
    function updateRoyaltyFeeManager(address _royaltyFeeManager) external onlyOwner {
        require(_royaltyFeeManager != address(0), "Owner: Cannot be null address");
        royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
        emit NewRoyaltyFeeManager(_royaltyFeeManager);
    }

    // ************* internal functions *************
    function _validateAsk(address _tokenContract, uint256 _tokenId, address _fillCurrency, uint256 _fillAmount)
        private
    {
        Ask storage ask = askForNFT[_tokenContract][_tokenId];

        require(ask.seller != address(0), "fillAsk must be active ask");
        require(ask.askCurrency == _fillCurrency, "fillAsk _fillCurrency must match ask currency");
        require(ask.askPrice == _fillAmount, "fillAsk _fillAmount must match ask amount");
        require(block.timestamp <= ask.expiry, "fillAsk ask has expired");
        require(ask.askCurrency == address(0) || msg.value == 0, "fillAsk askCurrency is not ETH");
    }

    function _fillAsk(address _tokenContract, uint256 _tokenId) private {
        Ask storage ask = askForNFT[_tokenContract][_tokenId];

        // Ensure ETH/ERC-20 payment from buyer is valid and take custody
        _handleIncomingTransfer(ask.askPrice, ask.askCurrency);

        uint256 remainingProfit =
            _handleRoyaltyPayout(_tokenContract, _tokenId, ask.askPrice, ask.askCurrency, USE_ALL_GAS_FLAG);

        remainingProfit = _handleProtocolFeePayout(remainingProfit, ask.askCurrency);

        // Transfer remaining ETH/ERC-20 to seller
        _handleOutgoingTransfer(ask.seller, remainingProfit, ask.askCurrency, USE_ALL_GAS_FLAG);

        // Transfer NFT to buyer
        erc721TransferHelper.transferFrom(_tokenContract, ask.seller, _msgSender(), _tokenId);

        ExchangeDetails memory userAExchangeDetails =
            ExchangeDetails({tokenContract: _tokenContract, tokenId: _tokenId, amount: 1});
        ExchangeDetails memory userBExchangeDetails =
            ExchangeDetails({tokenContract: ask.askCurrency, tokenId: 0, amount: ask.askPrice});

        emit ExchangeExecuted(ask.seller, _msgSender(), userAExchangeDetails, userBExchangeDetails);
        emit AskFilled(_tokenContract, _tokenId, _msgSender(), ask);

        delete askForNFT[_tokenContract][_tokenId];
    }

    function _cancelAsk(address _tokenContract, uint256 _tokenId) private {
        emit AskCancelled(_tokenContract, _tokenId, askForNFT[_tokenContract][_tokenId]);
        delete askForNFT[_tokenContract][_tokenId];
    }

    function _handleProtocolFeePayout(uint256 _amount, address _payoutCurrency) internal returns (uint256) {
        uint256 protocolFeeAmount = (fee * _amount) / _feeDenominator();
        if (protocolFeeAmount == 0) {
            return _amount;
        }

        _handleOutgoingTransfer(protocolFeeRecipient, protocolFeeAmount, _payoutCurrency, 50000);

        return _amount - protocolFeeAmount;
    }

    function _handleRoyaltyPayout(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _amount,
        address _payoutCurrency,
        uint256 _gasLimit
    )
        internal
        returns (uint256)
    {
        (address royaltyFeeRecipient, uint256 royaltyFeeAmount) =
            royaltyFeeManager.calculateRoyaltyFeeAndGetRecipient(_tokenContract, _tokenId, _amount);

        // Check if there is a royalty fee and that it is different to 0
        if ((royaltyFeeRecipient != address(0)) && (royaltyFeeAmount != 0)) {
            _handleOutgoingTransfer(royaltyFeeRecipient, royaltyFeeAmount, _payoutCurrency, _gasLimit);

            emit RoyaltyPayout(_tokenContract, _tokenId, royaltyFeeRecipient, _payoutCurrency, royaltyFeeAmount);

            return _amount - royaltyFeeAmount;
        } else {
            return _amount;
        }
    }

    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    function _msgSender()
        internal
        view
        virtual
        override (Context, ERC2771ContextFromStorage)
        returns (address sender)
    {
        return super._msgSender();
    }

    function _msgData() internal view virtual override (Context, ERC2771ContextFromStorage) returns (bytes calldata) {
        return super._msgData();
    }
}
