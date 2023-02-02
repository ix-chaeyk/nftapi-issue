// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockLinkToken is ERC20 {
    constructor() ERC20("ChainLink Token", "LINK") {
        _mint(msg.sender, 10 ** 27);
    }

    function transferAndCall(address to, uint256 value, bytes calldata) external returns (bool success) {
        return transfer(to, value);
    }
}
