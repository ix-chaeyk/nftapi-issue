// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract UniversalExchangeEventV1 {
    /// @notice The metadata of a token exchange
    /// @param tokenContract The address of the token contract
    /// @param tokenId The id of the token
    /// @param amount The number of tokens sent
    struct ExchangeDetails {
        address tokenContract;
        uint256 tokenId;
        uint256 amount;
    }

    /// @notice Emitted when a token exchange is executed
    /// @param userA The address of user A
    /// @param userB The address of a user B
    /// @param a The metadata of user A's exchange
    /// @param b The metadata of user B's exchange
    event ExchangeExecuted(address indexed userA, address indexed userB, ExchangeDetails a, ExchangeDetails b);
}
