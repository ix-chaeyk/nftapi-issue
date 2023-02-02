// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ModuleManager is Ownable {
    /// @notice Mapping of modules to registered status
    /// @dev Module address => Registered
    mapping(address => bool) public moduleRegistered;

    /// @notice Emitted when a module registration is changed
    /// @param module The address of the module
    /// @param registered The updated registration
    event ModuleRegistrationChanged(address indexed module, bool registered);

    /// @notice Registers a module
    /// @param _module The address of the module
    function setModuleRegistration(address _module, bool _registered) public onlyOwner {
        moduleRegistered[_module] = _registered;
        emit ModuleRegistrationChanged(_module, _registered);
    }

    function isModuleRegistered(address _module) external view returns (bool) {
        return moduleRegistered[_module];
    }
}
