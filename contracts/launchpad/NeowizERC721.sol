// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../lib/metatx/ERC2771ContextFromStorage.sol";
import "../external/erc721-with-permits/ERC721WithPermit.sol";
import "./interfaces/INeowizERC721.sol";

abstract contract NeowizERC721 is
    INeowizERC721,
    ERC721Burnable,
    ERC721Royalty,
    ERC721WithPermit,
    ERC2771ContextFromStorage,
    Ownable
{
    error NotExistingRound();
    error ZeroMaxTotalSupply();
    error WrongSaleRound();
    error RoundNotStarted();
    error InvalidTimestamp();
    error RoundEnded();
    error NotPublic();
    error NotPrivate();
    error NotSoldout();
    error NotAllRoundsFinished();
    error IncorrectProof();
    error NotEnoughFund();
    error NotEnoughERC20Fund();
    error PriceNotSet();
    error MaxMintExceeded(uint256 round);
    error MaxMintPerAccountExceeded(uint256 round, address account);
    error MaxTotalSupplyExceeded();
    error MaxTotalTeamMintExceeded();
    error AlreadyRevealed();

    address team;

    // base uri for nfts
    string private baseURI;

    // Valid currentRound starts from 1, and default is 0.
    uint256 private _currentRound;

    // The next token ID to be team-minted.
    uint256 private _currentTeamIndex;

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    uint256 public numRounds;
    mapping(uint256 => Round) public rounds;

    address public payment;
    uint256 public randomSeed;
    bool public revealed;
    string public unrevealedURI;
    uint256 public immutable TEAM_SUPPLY;
    uint256 public immutable MAX_TOTAL_SUPPLY;

    enum SaleState {
        PRIVATE,
        PUBLIC
    }

    /**
     * @dev In a round, users can mint until `round.totalMinted` == `round.maxMint`.
     * If it is the last round, users can mint more than maxMint until totalSupply() == MAX_TOTAL_SUPPLY.
     * `numberMinted` is necessary to allow users to mint multiple times in a round,
     * as long as they have minted less than `MAX_MINT_PER_ACCOUNT` in the round.;
     * @param state The minting round proceeds like CLOSED -> OG -> WL -> PUBLIC_0 -> PUBLIC_1.
     * However, any rounds may be omitted, i.e. a minting with only WL round is possible.
     */
    struct Round {
        mapping(address => uint256) numberMinted;
        uint256 maxMintPerAccount;
        uint256 maxMint;
        uint256 totalMinted;
        uint256 price;
        SaleState state;
        bytes32 merkleRoot;
        uint64 startTs;
        uint64 endTs;
    }

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
        ERC721(_name, _symbol)
        ERC2771ContextFromStorage(_trustedForwarder)
    {
        if (_maxTotalSupply == 0) {
            revert ZeroMaxTotalSupply();
        }
        MAX_TOTAL_SUPPLY = _maxTotalSupply;
        TEAM_SUPPLY = _currentIndex = _teamSupply;
        team = _team;
        payment = _payment;
        unrevealedURI = _unrevealedURI;
    }

    modifier whenSoldout() {
        if (totalMinted() < MAX_TOTAL_SUPPLY) {
            revert NotSoldout();
        }
        _;
    }

    modifier inRound(uint256 _round) {
        Round storage round = rounds[_round];
        if (numRounds < _round) {
            revert WrongSaleRound();
        }
        if (block.timestamp < round.startTs) {
            revert RoundNotStarted();
        }
        if (round.endTs <= block.timestamp) {
            revert RoundEnded();
        }
        _;
    }

    modifier isPublic(uint256 _round) {
        if (rounds[_round].state != SaleState.PUBLIC) {
            revert NotPublic();
        }
        _;
    }

    modifier isPrivate(uint256 _round) {
        SaleState state = rounds[_round].state;
        if (state != SaleState.PRIVATE) {
            revert NotPrivate();
        }
        _;
    }

    modifier checkRound(uint256 _roundId) {
        if (numRounds < _roundId) {
            revert NotExistingRound();
        }
        _;
    }

    function setTrustedForwarder(address _forwarder) external onlyOwner {
        _trustedForwarder = _forwarder;
        emit NewTrustedForwarder(_forwarder);
    }

    function burn(uint256 tokenId) public override (INeowizERC721, ERC721Burnable) {
        super.burn(tokenId);
        _burnCounter++;
    }

    function setPayment(address _payment) external onlyOwner {
        payment = _payment;
        emit PaymentUpdated(_payment);
    }

    function setUnRevealedURI(string memory _unrevealedURI) external onlyOwner {
        unrevealedURI = _unrevealedURI;
        emit UnrevealedURIUpdated(_unrevealedURI);
    }

    /// @param _state private or public
    /// @param _maxMintPerAccount The max amount of tokens one account can mint in this round
    /// @param _maxMint The max amount of tokens reserved in this round
    /// @param _price The unit price per token
    /// @param _merkleRoot This is useful only in a private round
    /// @param _startTs The timestamp when this round starts
    /// @param _endTs The timestamp when this round ends
    function addRound(
        SaleState _state,
        uint256 _maxMintPerAccount,
        uint256 _maxMint,
        uint256 _price,
        bytes32 _merkleRoot,
        uint256 _startTs,
        uint256 _endTs
    )
        external
        onlyOwner
    {
        if (_endTs < _startTs) {
            revert InvalidTimestamp();
        }
        if (_startTs < rounds[numRounds].endTs) {
            revert InvalidTimestamp();
        }

        Round storage r = rounds[++numRounds];
        r.state = _state;
        r.maxMintPerAccount = _maxMintPerAccount;
        r.maxMint = _maxMint;
        r.price = _price;
        r.merkleRoot = _merkleRoot;
        r.startTs = uint64(_startTs);
        r.endTs = uint64(_endTs);

        emit RoundAdded(numRounds, uint256(_state), _maxMintPerAccount, _maxMint, _price, _merkleRoot, _startTs, _endTs);
    }

    function updateState(uint256 _roundId, SaleState _state) external checkRound(_roundId) onlyOwner {
        Round storage r = rounds[_roundId];
        r.state = _state;

        emit StateUpdated(_roundId, uint256(_state));
    }

    function updateMaxMint(uint256 _roundId, uint256 _maxMint) external checkRound(_roundId) onlyOwner {
        Round storage r = rounds[_roundId];
        r.maxMint = _maxMint;
        emit MaxMintUpdated(_roundId, _maxMint);
    }

    function updateMaxMintPerAccount(uint256 _roundId, uint256 _maxMintPerAccount)
        external
        checkRound(_roundId)
        onlyOwner
    {
        Round storage r = rounds[_roundId];
        r.maxMintPerAccount = _maxMintPerAccount;
        emit MaxMintUpdated(_roundId, _maxMintPerAccount);
    }

    function updatePrice(uint256 _roundId, uint256 _price) external checkRound(_roundId) onlyOwner {
        Round storage r = rounds[_roundId];
        r.price = _price;
        emit PriceUpdated(_roundId, _price);
    }

    function updateMerkleRoot(uint256 _roundId, bytes32 _merkleRoot) external checkRound(_roundId) onlyOwner {
        Round storage r = rounds[_roundId];
        r.merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(_roundId, _merkleRoot);
    }

    /// @param _startTs _startTs must >= endTs of the previous round
    /// @param _endTs _endTs must <= startTs of the next round
    function updateRoundTimestamp(uint256 _roundId, uint256 _startTs, uint256 _endTs)
        external
        checkRound(_roundId)
        onlyOwner
    {
        if (_endTs < _startTs) {
            revert InvalidTimestamp();
        }
        Round storage r = rounds[_roundId];

        if (_roundId < numRounds && rounds[_roundId + 1].startTs < _endTs) {
            revert InvalidTimestamp();
        }

        if (1 < _roundId && _startTs < rounds[_roundId - 1].endTs) {
            revert InvalidTimestamp();
        }

        r.startTs = uint64(_startTs);
        r.endTs = uint64(_endTs);

        emit RoundTimestampUpdated(_roundId, _startTs, _endTs);
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        require(bytes(_uri).length > 0, "wrong base uri");
        baseURI = _uri;
        emit BaseURIUpdated(_uri);
    }

    /**
     * @notice Sets the contract-wide royalty info.
     */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
        emit RoyaltyInfoUpdated(receiver, feeBasisPoints);
    }

    /// @notice Mint unminted nfts before the reveal. This excludes the team amount.
    /// @param _to the address to send
    /// @param _quantity Given type(uint256).max, mint all remainders except for the team amount.
    function mintResidue(address _to, uint256 _quantity) external onlyOwner {
        // Check
        if (_quantity == type(uint256).max) {
            _quantity = _notTeamResidue();
        }
        if (block.timestamp < rounds[numRounds].endTs) {
            revert NotAllRoundsFinished();
        }
        if (_notTeamResidue() < _quantity) {
            revert MaxTotalSupplyExceeded();
        }

        // Effect
        _currentIndex += _quantity;

        // Interaction
        _mintNotTeamQuantity(_to, _quantity);
    }

    function teamMint(uint256 _quantity) external onlyOwner {
        if (_quantity == type(uint256).max) {
            _quantity = TEAM_SUPPLY - totalTeamMinted();
        }
        if (TEAM_SUPPLY < totalTeamMinted() + _quantity) {
            revert MaxTotalTeamMintExceeded();
        }

        _currentTeamIndex += _quantity;

        _mintTeamQuantity(team, _quantity);
    }

    /// @dev Public round may be more than 1.
    /// @param _round It is always satisfied `_round >= uint256(SaleRound.PUBLIC)`.
    ///               Unless unauthorized users can mint in OG, WL rounds.
    function publicMint(uint256 _quantity, uint256 _round, address _payment, uint256 _price)
        external
        payable
        inRound(_round)
        isPublic(_round)
    {
        Round storage round = rounds[_round];
        require(_payment == address(payment), "payment is different");
        require(_price == round.price, "round price is different");

        _mintInRound(_round, _msgSender(), _quantity);
    }

    /// @notice Private round only allows whitelisted users.
    function privateMint(
        bytes32[] calldata _merkleProof,
        uint256 _quantity,
        uint256 _round,
        address _payment,
        uint256 _price
    )
        external
        payable
        inRound(_round)
        isPrivate(_round)
    {
        Round storage round = rounds[_round];
        require(_payment == address(payment), "payment is different");
        require(_price == round.price, "round price is different");

        checkValidity(_merkleProof, rounds[_round].merkleRoot, _msgSender());
        _mintInRound(_round, _msgSender(), _quantity);
    }

    function publicMintWithPermit(
        uint256 _quantity,
        uint256 _round,
        address _payment,
        uint256 _price,
        uint256 _deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        inRound(_round)
        isPublic(_round)
    {
        Round storage round = rounds[_round];
        require(_payment == address(payment), "payment is different");
        require(_price == round.price, "round price is different");

        _permitPayment(round.price * _quantity, _deadline, v, r, s);
        _mintInRound(_round, _msgSender(), _quantity);
    }

    function privateMintWithPermit(
        bytes32[] calldata _merkleProof,
        uint256 _quantity,
        uint256 _round,
        address _payment,
        uint256 _price,
        uint256 _deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        payable
        inRound(_round)
        isPrivate(_round)
    {
        Round storage round = rounds[_round];
        require(_payment == payment, "payment is different");
        require(_price == round.price, "round price is different");

        checkValidity(_merkleProof, round.merkleRoot, _msgSender());
        _permitPayment(round.price * _quantity, _deadline, v, r, s);
        _mintInRound(_round, _msgSender(), _quantity);
    }

    function checkValidity(bytes32[] calldata _merkleProof, bytes32 _root, address _to) public pure {
        bytes32 leaf = keccak256(abi.encodePacked(_to));
        if (!MerkleProof.verifyCalldata(_merkleProof, _root, leaf)) {
            revert IncorrectProof();
        }
    }

    function withdraw() external payable onlyOwner {
        if (address(payment) == address(0)) {
            (bool success,) = payable(_msgSender()).call{value: address(this).balance}("");
            require(success);
        } else {
            uint256 balance = IERC20(payment).balanceOf(address(this));
            IERC20(payment).transfer(_msgSender(), balance);
        }
    }

    /**
     * @notice It is allowed to set the random seed before all tokens are minted.
     */
    function _setRandomSeed(uint256 _randomSeed) internal {
        if (revealed) {
            revert AlreadyRevealed();
        }
        randomSeed = _randomSeed % (MAX_TOTAL_SUPPLY - TEAM_SUPPLY);
        revealed = true;

        emit Revealed();
    }

    function _permitPayment(uint256 value, uint256 _deadline, uint8 v, bytes32 r, bytes32 s) internal {
        IERC20Permit(payment).permit(_msgSender(), address(this), value, _deadline, v, r, s);
    }

    /// @dev tokenId is guaranteed to be less than `MAX_TOTAL_SUPPLY`.
    function _mintInRound(uint256 _round, address _to, uint256 _quantity) internal {
        // check
        Round storage round = rounds[_round];
        uint256 totalPrice = round.price * _quantity;
        if (payment != address(0)) {
            if (IERC20(payment).balanceOf(_to) < totalPrice) {
                revert NotEnoughERC20Fund();
            }
        } else {
            if (msg.value < totalPrice) {
                revert NotEnoughFund();
            }
        }
        if (round.maxMintPerAccount < round.numberMinted[_to] + _quantity) {
            revert MaxMintPerAccountExceeded(_round, _to);
        }

        // Skip round.maxMint check if it is the last round
        if (_round != numRounds && round.maxMint < (round.totalMinted + _quantity)) {
            revert MaxMintExceeded(_round);
        }

        if (_notTeamResidue() < _quantity) {
            revert MaxTotalSupplyExceeded();
        }

        // effect
        round.numberMinted[_msgSender()] += _quantity;
        round.totalMinted += _quantity;
        _currentIndex += _quantity;

        // interaction
        _mintNotTeamQuantity(_to, _quantity);
        if (payment != address(0)) {
            IERC20(payment).transferFrom(_to, address(this), totalPrice);
        }
    }

    function _transfer(address from, address to, uint256 tokenId) internal override (ERC721, ERC721WithPermit) {
        super._transfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override (ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    /// @dev Before this, increase _currentTeamIndex and check all validations
    function _mintTeamQuantity(address _to, uint256 _quantity) private {
        uint256 startId = _currentTeamIndex - _quantity;
        for (uint256 i = startId; i < startId + _quantity; i++) {
            _safeMint(_to, i);
        }
    }

    /// @dev Before this, increase _currentIndex and check all validations
    function _mintNotTeamQuantity(address _to, uint256 _quantity) private {
        uint256 startId = _currentIndex - _quantity;
        for (uint256 i = startId; i < startId + _quantity; i++) {
            _safeMint(_to, i);
        }
    }

    // ************* view functions *************
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override (ERC721, ERC721Royalty, ERC721WithPermit)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function isRevealed() public view override returns (bool) {
        return revealed;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented more than `_currentIndex` times.
        unchecked {
            return totalMinted() - _burnCounter;
        }
    }

    /**
     * @notice Returns the total amount of tokens minted in the contract.
     */
    function totalMinted() public view returns (uint256) {
        unchecked {
            return _currentIndex - TEAM_SUPPLY + _currentTeamIndex;
        }
    }

    /**
     * @notice Returns the total amount of tokens minted by the team.
     */
    function totalTeamMinted() public view returns (uint256) {
        return _currentTeamIndex;
    }

    function currentRound() public view returns (uint256) {
        Round storage r;
        for (uint256 i = 1; i <= numRounds; i++) {
            r = rounds[i];
            if (r.startTs <= block.timestamp && block.timestamp < r.endTs) {
                return i;
            }
        }

        return 0;
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        if (!revealed) {
            return unrevealedURI;
        }

        uint256 shiftedId;
        if (tokenId < TEAM_SUPPLY) {
            shiftedId = tokenId;
        } else {
            shiftedId = ((tokenId - TEAM_SUPPLY + randomSeed) % (MAX_TOTAL_SUPPLY - TEAM_SUPPLY)) + TEAM_SUPPLY;
        }

        return super.tokenURI(shiftedId);
    }

    function numberMintedInRound(address _account, uint256 _round) external view returns (uint256) {
        return rounds[_round].numberMinted[_account];
    }

    function _notTeamResidue() internal view returns (uint256) {
        unchecked {
            return MAX_TOTAL_SUPPLY - _currentIndex;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
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
