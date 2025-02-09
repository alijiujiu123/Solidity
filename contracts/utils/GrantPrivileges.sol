// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/utils/SlotDerivation.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
 * @title GrantPrivileges
 * @dev Abstract contract to manage time-based access control for specific functions.
 * Admin can grant temporary access to users, enabling functionalities like subscriptions
 * or time-limited permissions.
 *
 * ## Usage Example:
 * contract EatFoodContract is GrantPrivileges {
 *     function eatFood(string calldata str) external view onlyOwner returns (bytes32) {
 *         return keccak256(abi.encode(str));
 *     }
 * }
 *
 * 1. Inherit from `GrantPrivileges` in your contract.
 * 2. Use `onlyAdmin` for admin-restricted functions and `onlyOwner` for time-limited access control.
 * 3. Deploy your contract, and the deploying address will be the initial admin.
 * 4. Admin can add authorized users using `addOwner()`.
 * 5. Authorized users can access `onlyOwner` functions within the granted time frame.
 */
abstract contract GrantPrivileges {
    using SlotDerivation for *;
    using StorageSlot for *;

    string public constant GRANTPRIVILEGES_NAMESPACE = "GrantPrivileges.Namespace";

    // Custom errors for better gas efficiency and debugging
    error AddressEmpty();
    error TimeLimitZero();
    error OnlyAdmin(string info);
    error OnlyLegalOwner(string info);

    // Storage key for admin address
    string private constant ADMIN_ADDRESS = "GrantPrivileges.adminAddress";

    /**
     * @dev Retrieves the current admin address from the storage slot.
     */
    function _getAdminAddress() private view returns (address) {
        return ADMIN_ADDRESS.erc7201Slot().getAddressSlot().value;
    }

    /**
     * @dev Sets a new admin address in the storage slot.
     * @param _newAddress New admin address.
     */
    function _setAdminAddress(address _newAddress) private {
        ADMIN_ADDRESS.erc7201Slot().getAddressSlot().value = _newAddress;
    }

    // Struct to store information about authorized users
    struct OwnerInfo {
        uint timestamp;    // The time when authorization starts
        uint timeLimit;    // Duration of authorization in seconds
    }

    /**
     * @dev Retrieves the storage slot for an owner's authorization info.
     * @param slot The storage slot derived for the owner.
     */
    function _getOwnerInfoSlot(bytes32 slot) private pure returns (OwnerInfo storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns the OwnerInfo struct for a given address.
     * @param _address Address of the owner to fetch authorization info.
     */
    function _getOwnerInfoByAddress(address _address) private pure returns (OwnerInfo storage r) {
        bytes32 ownerInfoSlot = GRANTPRIVILEGES_NAMESPACE.erc7201Slot().deriveMapping(_address);
        return _getOwnerInfoSlot(ownerInfoSlot);
    }

    /**
     * @dev Constructor sets the deploying address as the initial admin.
     */
    constructor() {
        _setAdminAddress(msg.sender);
    }

    // Modifiers for access control

    /**
     * @dev Restricts function access to the admin only.
     */
    modifier onlyAdmin() {
        if (msg.sender != _getAdminAddress()) {
            revert OnlyAdmin("only admin address can access");
        }
        _;
    }

    /**
     * @dev Restricts function access to the admin or valid authorized users.
     */
    modifier onlyOwner() {
        if (msg.sender != _getAdminAddress() && !_legalOwner(msg.sender)) {
            revert OnlyLegalOwner("only legal owner address can access");
        }
        _;
    }

    /**
     * @dev Checks if an address is within its authorized period.
     * @param senderAddress The address to verify.
     */
    function _legalOwner(address senderAddress) private view returns (bool) {
        OwnerInfo storage ownerInfo = _getOwnerInfoByAddress(senderAddress);
        uint timestamp = ownerInfo.timestamp;
        uint timeLimit = ownerInfo.timeLimit;

        if (timestamp == 0 || timeLimit == 0) {
            return false; // Not authorized
        }

        // Check if authorization has expired
        if (block.timestamp > (timestamp + timeLimit)) {
            return false;
        }
        return true;
    }

    /**
     * @dev Adds a new authorized user with a time limit.
     * @param newOwner Address of the new user.
     * @param _timeLimit Duration of access in seconds.
     */
    function addOwner(address newOwner, uint _timeLimit) external onlyAdmin {
        if (newOwner == address(0)) {
            revert AddressEmpty();
        }
        if (_timeLimit == 0) {
            revert TimeLimitZero();
        }
        OwnerInfo storage ownerInfo = _getOwnerInfoByAddress(newOwner);
        ownerInfo.timestamp = block.timestamp;
        ownerInfo.timeLimit = _timeLimit;
    }

    /**
     * @dev Allows authorized users to check their remaining access time.
     * @return Remaining time in seconds, or 0 if authorization has expired.
     */
    function getRemainingTime() external view onlyOwner returns (uint) {
        OwnerInfo storage ownerInfo = _getOwnerInfoByAddress(msg.sender);
        uint timestamp = ownerInfo.timestamp;
        uint timeLimit = ownerInfo.timeLimit;

        if (timestamp == 0 || timeLimit == 0) {
            return 0; // No authorization
        }

        if ((timestamp + timeLimit) < block.timestamp) {
            return 0; // Authorization expired
        }

        return (timestamp + timeLimit) - block.timestamp;
    }

    /**
     * @dev Public function to get the current admin address.
     * @return Admin address.
     */
    function getAdminAddress() external view returns (address) {
        return _getAdminAddress();
    }

    /**
     * @dev Allows the current admin to transfer admin privileges to a new address.
     * @param newAdmin Address of the new admin.
     */
    function changeAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) {
            revert AddressEmpty();
        }
        _setAdminAddress(newAdmin);
    }
}
