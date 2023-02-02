// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../NeowizGameItem.sol";

contract NeowizGameItemV2 is NeowizGameItem {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _forwarder) NeowizGameItem(_forwarder) {}

    function foo() public pure returns (uint256) {
        return 1;
    }
}
