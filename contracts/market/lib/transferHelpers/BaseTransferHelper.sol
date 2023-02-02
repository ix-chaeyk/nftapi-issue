// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {ModuleManager} from "../../ModuleManager.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract BaseTransferHelper is Context {
    /// @notice The Module Manager
    ModuleManager public immutable MM;

    /// @param _moduleManager The Module Manager to check permissions
    constructor(address _moduleManager) {
        require(_moduleManager != address(0), "must set module manager to non-zero address");

        MM = ModuleManager(_moduleManager);
    }

    /// @notice Ensures the module is regisered.
    modifier onlyRegisteredModule() {
        require(isModuleRegistered(), "module has not been registered");
        _;
    }

    /// @notice Return if the msgSender() module is registered in ModuleManager
    function isModuleRegistered() public view returns (bool) {
        return MM.isModuleRegistered(_msgSender());
    }
}
