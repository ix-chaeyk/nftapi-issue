// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/ICollectionManager.sol";

/**
 * @title CollectionManager
 * @notice It allows adding/removing NFTs for trading on the exchange.
 */
contract CollectionManager is ICollectionManager, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _whitelistedTokens;

    event TokenRemoved(address indexed token);
    event TokenWhitelisted(address indexed token);

    /**
     * @notice Add a token in the system
     * @param token address of the token to add
     */
    function addToken(address token) external override onlyOwner {
        require(!_whitelistedTokens.contains(token), "Token: Already whitelisted");
        _whitelistedTokens.add(token);

        emit TokenWhitelisted(token);
    }

    /**
     * @notice Remove a token from the system
     * @param token address of the token to remove
     */
    function removeToken(address token) external override onlyOwner {
        require(!_whitelistedTokens.contains(token), "Token: Not whitelisted");
        _whitelistedTokens.remove(token);

        emit TokenRemoved(token);
    }

    /**
     * @notice Returns if a token is in the system
     * @param token address of the token
     */
    function isTokenWhitelisted(address token) external view override returns (bool) {
        return _whitelistedTokens.contains(token);
    }

    /**
     * @notice View number of whitelisted currencies
     */
    function viewCountWhitelistedTokens() external view override returns (uint256) {
        return _whitelistedTokens.length();
    }

    /**
     * @notice See whitelisted currencies in the system
     * @param cursor cursor (should start at 0 for first request)
     * @param size size of the response (e.g., 50)
     */
    function viewWhitelistedTokens(uint256 cursor, uint256 size)
        external
        view
        override
        returns (address[] memory, uint256)
    {
        uint256 length = size;

        if (length > _whitelistedTokens.length() - cursor) {
            length = _whitelistedTokens.length() - cursor;
        }

        address[] memory whitelistedTokens = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            whitelistedTokens[i] = _whitelistedTokens.at(cursor + i);
        }

        return (whitelistedTokens, cursor + length);
    }
}
