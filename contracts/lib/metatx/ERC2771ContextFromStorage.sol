// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/// @notice OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support using a non-immutable storage variable.
 */
abstract contract ERC2771ContextFromStorage is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address internal _trustedForwarder;

    event NewTrustedForwarder(address indexed trustedForwarder);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}
