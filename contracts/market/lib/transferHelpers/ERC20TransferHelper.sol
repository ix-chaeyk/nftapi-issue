// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BaseTransferHelper} from "./BaseTransferHelper.sol";

contract ERC20TransferHelper is BaseTransferHelper {
    using SafeERC20 for IERC20;

    constructor(address _moduleManager) BaseTransferHelper(_moduleManager) {}

    function safeTransferFrom(address _token, address _from, address _to, uint256 _value) public onlyRegisteredModule {
        IERC20(_token).safeTransferFrom(_from, _to, _value);
    }
}
