// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "contracts/proxy/ERC1967/ERC1967Utils.sol";

/**
 * @title ProxyAdmin
 * @dev This contract manages administrative control for an upgradeable proxy contract.
 * It handles admin permissions and allows the admin to change the admin address securely.
 */
contract ProxyAdmin {
    
    /**
     * @dev Custom error for unauthorized access attempts.
     * @param data A descriptive error message.
     */
    error NotAdminError(string data);

    /**
     * @dev Initializes the contract by setting the initial admin address.
     * The admin address is stored in the predefined ADMIN_SLOT from ERC1967Utils.
     * @param _adminAddress The address of the initial admin.
     */
    constructor1(address _adminAddress) {
        ERC1967Utils.setAdminAddress(_adminAddress);
    }

    /**
     * @dev Modifier that restricts function access to the current admin only.
     * Reverts with a `NotAdminError` if the caller is not the admin.
     */
    modifier onlyAdmin() {
        if (msg.sender != ERC1967Utils.getAdminAddress()) {
            revert NotAdminError("Only admin can call this function");
        }
        _;
    }

    /**
     * @dev Changes the admin address to a new one.
     * Can only be called by the current admin.
     * @param _newAdmin The new admin address.
     */
    function _changeAdmin(address _newAdmin) internal onlyAdmin {
        ERC1967Utils.setAdminAddress(_newAdmin);
    }

    /**
     * @dev Retrieves the current admin address.
     * @return The address of the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return ERC1967Utils.getAdminAddress();
    }
}
