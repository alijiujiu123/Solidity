// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "contracts/LogLibrary.sol";
import "contracts/proxy/ERC1967/ERC1967Utils.sol";
import "contracts/proxy/ERC1967/ProxyAdmin.sol";

/**
 * @title TransparentUpgradeableProxy
 * @dev This contract implements a transparent proxy pattern that forwards calls 
 * to an implementation (logic) contract. It allows for upgrading the logic contract 
 * and changing the admin, while ensuring storage layout consistency through custom 
 * storage slots as per EIP-1967.
 * 
 * Features:
 * 1. Fallback function forwards calls to the logic contract.
 * 2. Assembly-based handling of return data in fallback.
 * 3. Upgradable logic contract and adjustable admin permissions.
 * 4. Consistent storage layout using custom storage slots (ERC1967 standard).
 * 5. Initialization logic executed upon deployment or upgrades.
 */
contract TransparentUpgradeableProxy is ProxyAdmin {
    using LogLibrary for *;

    /// @dev Error thrown when a zero address is provided.
    error AddressEmptyError();

    /// @dev Emitted when a fallback call is forwarded to the logic contract.
    event FallbackLog(address indexed from, bytes4 indexed msgSig, bytes msgData);

    /// @dev Emitted when the logic contract is upgraded and initialization logic is executed.
    event UpgradeAndCallLog(address indexed logicAddress, bytes data, bool success, bytes resultData);

    /**
     * @dev Constructor that sets the initial logic contract and optionally initializes it.
     * @param _logicAddress The address of the initial logic contract.
     * @param data Initialization data encoded as bytes (e.g., abi.encodeWithSignature).
     */
    constructor(address _logicAddress, bytes memory data) ProxyAdmin(msg.sender) {
        _upgradeAndCall(_logicAddress, data);
    }

    /**
     * @dev Fallback function that forwards calls to the logic contract.
     * Emits a `FallbackLog` event and uses delegatecall to forward the request.
     */
    fallback() external payable {
        emit FallbackLog(msg.sender, msg.sig, msg.data);
        // Forward the call to the logic contract
        ERC1967Utils.delegatecall();
    }

    /**
     * @dev Allows the contract to receive Ether without triggering fallback.
     */
    receive() external payable {}

    /**
     * @dev Allows the admin to upgrade the logic contract and optionally initialize it.
     * @param newLogicAddress The address of the new logic contract.
     * @param data Initialization data to be executed on the new logic contract.
     */
    function upgradeLogicAddress(address newLogicAddress, bytes memory data) external onlyAdmin {
        _upgradeAndCall(newLogicAddress, data);
    }

    /**
     * @dev Internal function to handle logic contract upgrades and optional initialization.
     * @param _address The address of the new logic contract.
     * @param data Initialization data to be executed after upgrading.
     */
    function _upgradeAndCall(address _address, bytes memory data) private {
        if (_address == address(0)) {
            revert AddressEmptyError();
        }

        // Update the logic contract address in storage
        ERC1967Utils.setImplementationAddress(_address);

        // Execute initialization logic if provided
        if (data.length > 0) {
            (bool success, bytes memory resultData) = _address.delegatecall(data);
            emit UpgradeAndCallLog(_address, data, success, resultData);
        }
    }

    /**
     * @dev Allows the admin to change the admin address.
     * @param _newAdmin The address of the new admin.
     */
    function changeAdmin(address _newAdmin) external onlyAdmin {
        super._changeAdmin(_newAdmin);
    }

    /**
     * @dev Retrieves the current admin address.
     * @return The address of the current admin.
     */
    function getAdmin() external view returns (address) {
        return ERC1967Utils.getAdminAddress();
    }
}
