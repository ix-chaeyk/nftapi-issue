// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IRoyaltyFeeRegistry} from "../interfaces/IRoyaltyFeeRegistry.sol";

/**
 * @title RoyaltyFeeSetter
 * @notice It is used to allow creators to set royalty parameters in the RoyaltyFeeRegistry.
 */
contract RoyaltyFeeSetter is Ownable {
    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    // ERC2981 interfaceID
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    address public immutable royaltyFeeRegistry;

    /**
     * @notice Constructor
     * @param _royaltyFeeRegistry address of the royalty fee registry
     */
    constructor(address _royaltyFeeRegistry) {
        royaltyFeeRegistry = _royaltyFeeRegistry;
    }

    /**
     * @notice Update royalty info for collection if owner
     * @dev Can only be called by the NFT contract owner
     * @param collection address of the NFT contract
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollectionIfOwner(address collection, address receiver, uint256 fee) external {
        require(msg.sender == Ownable(collection).owner(), "Setter: caller is not the NFT owner");

        _updateRoyaltyInfoForCollectionIfOwner(collection, receiver, fee);
    }

    /**
     * @notice Update royalty info for collection
     * @dev Can only be called by contract owner (of this)
     * @param collection address of the NFT contract
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollection(address collection, address receiver, uint256 fee) external onlyOwner {
        IRoyaltyFeeRegistry(royaltyFeeRegistry).updateRoyaltyInfoForCollection(collection, receiver, fee);
    }

    /**
     * @notice Update owner of royalty fee registry
     * @dev Can be used for migration of this royalty fee setter contract
     * @param _owner new owner address
     */
    function updateOwnerOfRoyaltyFeeRegistry(address _owner) external onlyOwner {
        Ownable(royaltyFeeRegistry).transferOwnership(_owner);
    }

    /**
     * @notice Update royalty info for collection
     * @param _royaltyFeeLimit new royalty fee limit (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external onlyOwner {
        IRoyaltyFeeRegistry(royaltyFeeRegistry).updateRoyaltyFeeLimit(_royaltyFeeLimit);
    }

    /**
     * @notice Update information and perform checks before updating royalty fee registry
     * @param collection address of the NFT contract
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function _updateRoyaltyInfoForCollectionIfOwner(address collection, address receiver, uint256 fee) internal {
        require(
            (
                IERC165(collection).supportsInterface(INTERFACE_ID_ERC721)
                    || IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)
            ),
            "Setter: Not ERC721/ERC1155"
        );

        IRoyaltyFeeRegistry(royaltyFeeRegistry).updateRoyaltyInfoForCollection(collection, receiver, fee);
    }
}
