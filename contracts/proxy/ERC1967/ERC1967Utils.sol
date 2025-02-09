// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title ERC1967Utils
 * @dev This library manages key storage slots for an ERC1967 proxy contract, including
 * the logic contract address (implementation) and the admin address.
 * It also provides low-level delegatecall functionality to delegate calls to the implementation contract.
 */
library ERC1967Utils {
    /**
     * @dev Custom storage slot structure to hold address type data.
     */
    struct AddressSlot {
        address value;
    }

    /**
     * @dev Storage slot for the current implementation (logic contract) address.
     * This slot is defined as keccak-256("eip1967.proxy.implementation") minus 1.
     * This is part of the EIP-1967 standard to avoid storage collisions.
     */
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Retrieves the current implementation address stored in the IMPLEMENTATION_SLOT.
     * @return The address of the current implementation contract.
     */
    function getImplementationAddress() internal view returns(address) {
        return getAddressSlot(IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Sets a new implementation address in the IMPLEMENTATION_SLOT.
     * @param _implementationAddress The new implementation contract address.
     */
    function setImplementationAddress(address _implementationAddress) internal {
        getAddressSlot(IMPLEMENTATION_SLOT).value = _implementationAddress;
    }

    /**
     * @dev Storage slot for the admin address of the contract.
     * This slot is defined as keccak-256("eip1967.proxy.admin") minus 1.
     * This is part of the EIP-1967 standard for secure admin address storage.
     */
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Retrieves the current admin address stored in the ADMIN_SLOT.
     * @return The address of the current admin.
     */
    function getAdminAddress() internal view returns(address) {
        return getAddressSlot(ADMIN_SLOT).value;
    }

    /**
     * @dev Sets a new admin address in the ADMIN_SLOT.
     * @param _adminAddress The new admin address.
     */
    function setAdminAddress(address _adminAddress) internal {
        getAddressSlot(ADMIN_SLOT).value = _adminAddress;
    }

    /**
     * @dev Returns an AddressSlot struct that represents the address stored at the given slot.
     * This function uses inline assembly to access the specific storage slot.
     * @param slot The storage slot to access.
     * @return r An AddressSlot struct containing the address stored at the specified slot.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Delegates the current call to the implementation address stored in IMPLEMENTATION_SLOT.
     */
    function delegatecall() internal {
        _delegate(getImplementationAddress());
    }

    /**
     * @dev Low-level delegatecall implementation.
     * Delegates the current call to the provided implementation address.
     * @param implementation The address of the implementation contract to delegate the call to.
     */
    function _delegate(address implementation) private {
        assembly {
            // Copy call data to memory starting at position 0
            calldatacopy(0, 0, calldatasize())

            // Perform the delegatecall with the provided implementation address
            // gas() provides the remaining gas, calldatasize() provides input size
            // Output is stored at position 0, but size is unknown initially
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy returned data to memory
            returndatacopy(0, 0, returndatasize())

            // Check if the delegatecall was successful or not
            switch result
            case 0 {
                // If delegatecall failed, revert the transaction and return the error data
                revert(0, returndatasize())
            }
            default {
                // If delegatecall succeeded, return the data to the caller
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev Generates a storage slot based on the provided string.
     * This function computes the keccak256 hash of the string and subtracts 1 to match the EIP-1967 standard.
     * @param data The input string to generate the storage slot from.
     * @return The generated storage slot as a bytes32 value.
     */
    function generateStorageSlot(string memory data) public pure returns (bytes32) {
        return bytes32(uint256(keccak256(bytes(data))) - 1);
    }
}
