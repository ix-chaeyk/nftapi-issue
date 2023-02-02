// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICollectionManager {
    function addToken(address token) external;

    function removeToken(address token) external;

    function isTokenWhitelisted(address token) external view returns (bool);

    function viewWhitelistedTokens(uint256 cursor, uint256 size) external view returns (address[] memory, uint256);

    function viewCountWhitelistedTokens() external view returns (uint256);
}
