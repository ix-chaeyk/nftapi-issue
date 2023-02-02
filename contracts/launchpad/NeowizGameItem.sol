// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/INeowizERC721.sol";
import "./interfaces/INeowizGameItem.sol";
import "../external/erc721-with-permits/ERC721WithPermitUpgradeable.sol";

contract NeowizGameItem is
    INeowizGameItem,
    IERC721Receiver,
    Initializable,
    UUPSUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721WithPermitUpgradeable,
    ERC2771ContextUpgradeable,
    OwnableUpgradeable
{
    uint256 public numberMinted;
    mapping(address => bool) allowed;
    mapping(uint256 => bool) locked;

    function _transfer(address from, address to, uint256 tokenId)
        internal
        virtual
        override (ERC721Upgradeable, ERC721WithPermitUpgradeable)
    {
        super._transfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721Upgradeable, ERC721WithPermitUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    modifier onlyAllowed(address _launchpad) {
        if (!allowed[_launchpad]) {
            revert NotAllowedLaunchpad();
        }
        _;
    }

    modifier onlyOwnerOrTokenOwner(uint256 _tokenId) {
        address sender = _msgSender();
        if (sender != owner() && sender != ownerOf(_tokenId)) {
            revert NotOwnerOrTokenOwner();
        }
        _;
    }

    // NOTE: Upgrade to another implementation to use a different forwarder.
    // Reference: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/issues/143
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _trustedForwarder) ERC2771ContextUpgradeable(_trustedForwarder) {}

    function initialize(string memory _name, string memory _symbol) public virtual initializer {
        __ERC721_init(_name, _symbol);
        __ERC721WithPermit__init();
        __ERC721Burnable_init();
        __ERC721URIStorage_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /// @notice Mint GameItem and burn launchpad nft.
    /// It is assumed that the migrated token is approved to this contract.
    function migrate(address _launchpad, uint256 _tokenId) external override onlyAllowed(_launchpad) {
        string memory uri = IERC721Metadata(_launchpad).tokenURI(_tokenId);
        address tokenOwner = IERC721(_launchpad).ownerOf(_tokenId);
        _mintWithURI(tokenOwner, uri);

        if (!INeowizERC721(_launchpad).isRevealed()) {
            revert NotRevealed();
        }

        IERC721Metadata(_launchpad).transferFrom(tokenOwner, address(this), _tokenId);
        INeowizERC721(_launchpad).burn(_tokenId);
    }

    function mint(address _to, string memory _uri) public override onlyOwner {
        _mintWithURI(_to, _uri);
    }

    function burn(uint256 _tokenId)
        public
        override (INeowizGameItem, ERC721BurnableUpgradeable)
        onlyOwnerOrTokenOwner(_tokenId)
    {
        _burn(_tokenId);
    }

    function lock(uint256 _tokenId) external override onlyOwnerOrTokenOwner(_tokenId) {
        locked[_tokenId] = true;
        emit Lock(_tokenId);
    }

    function unlock(uint256 _tokenId) external override onlyOwnerOrTokenOwner(_tokenId) {
        locked[_tokenId] = false;
        emit Unlock(_tokenId);
    }

    function allowLaunchpad(address _launchpad) external override onlyOwner {
        allowed[_launchpad] = true;
        emit LaunchpadAllowed(_launchpad);
    }

    function denyLaunchpad(address _launchpad) external override onlyOwner {
        allowed[_launchpad] = false;
        emit LaunchpadDenied(_launchpad);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override (ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(_tokenId);
    }

    //********** internal **********/
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _mintWithURI(address _to, string memory _uri) internal {
        uint256 tokenId = numberMinted++;
        _mint(_to, tokenId);
        _setTokenURI(tokenId, _uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        if (locked[tokenId]) {
            revert Locked();
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 _tokenId) internal override (ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(_tokenId);
    }

    function _msgSender()
        internal
        view
        override (ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        override (ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes memory callData)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}
