// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/SlotDerivation.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title DiamondStorage Library
 * @dev Provides custom storage structures and utility functions for EIP-2535 (Diamond Standard).
 * 
 * 1. Implements a customizable mapping from `bytes4` (function selectors) to `address`.
 * 2. Provides a customizable, enumerable mapping from `address` to `DiamondFacet`, supporting extensible facet storage.
 */
library DiamondStorage {
    // ***************************** Part One: bytes4 -> address ***********************************************************
    using SlotDerivation for *;
    using StorageSlot for *;

    // Namespace for bytes4 to address mapping
    string private constant DIAMOND_STORAGE_NAMESPACE_BYTES4_TO_ADDRESS_MAP = "DiamondStorage.namespace.bytes4ToAddressMap";
    
    type Bytes4ToAddressMap is bytes32;

    /**
     * @dev Retrieves the slot for a Bytes4ToAddressMap by its name.
     * @param mapName The name of the map.
     * @return The wrapped bytes32 representing the storage slot.
     */
    function getBytes4ToAddressMap(string memory mapName) internal pure returns (Bytes4ToAddressMap) {
        bytes32 mapSlot = _concat(DIAMOND_STORAGE_NAMESPACE_BYTES4_TO_ADDRESS_MAP, mapName).erc7201Slot();
        return Bytes4ToAddressMap.wrap(mapSlot);
    }

    /**
     * @dev Gets the address associated with a specific bytes4 key.
     * @param _map The Bytes4ToAddressMap storage.
     * @param key The function selector.
     * @return The address mapped to the given function selector.
     */
    function get(Bytes4ToAddressMap _map, bytes4 key) internal view returns (address) {
        return _getAddressSlot(Bytes4ToAddressMap.unwrap(_map), key).value;
    }

    /**
     * @dev Sets the address for a given bytes4 key in the map.
     * @param _map The Bytes4ToAddressMap storage.
     * @param key The function selector.
     * @param _value The address to be mapped.
     */
    function set(Bytes4ToAddressMap _map, bytes4 key, address _value) internal {
        _getAddressSlot(Bytes4ToAddressMap.unwrap(_map), key).value = _value;
    }

    /**
     * @dev Removes the mapping for a specific bytes4 key.
     * @param _map The Bytes4ToAddressMap storage.
     * @param key The function selector to be removed.
     */
    function remove(Bytes4ToAddressMap _map, bytes4 key) internal {
        delete _getAddressSlot(Bytes4ToAddressMap.unwrap(_map), key).value;
    }

    /**
     * @dev Internal function to compute the storage slot for a given key.
     * @param mapSlot The base slot of the map.
     * @param key The function selector.
     * @return The StorageSlot.AddressSlot corresponding to the key.
     */
    function _getAddressSlot(bytes32 mapSlot, bytes4 key) private pure returns (StorageSlot.AddressSlot storage) {
        bytes32 keyData = bytes32(key);
        bytes32 keySlot = mapSlot.deriveMapping(keyData);
        return keySlot.getAddressSlot();
    }

    /**
     * @dev Concatenates two strings with a period separator.
     * @param str1 The first string.
     * @param str2 The second string.
     * @return The concatenated string.
     */
    function _concat(string memory str1, string memory str2) private pure returns (string memory) {
        return string(abi.encodePacked(str1, ".", str2));
    }

    // ***************************** Part Two: address -> DiamondFacet ***********************************************************
    using EnumerableSet for *;

    error AddressKeyZero(address key, DiamondFacet value);
    error AddressToFacetMapNonexistentKey(address key);

    // Namespace for address to DiamondFacet mapping
    string private constant DIAMOND_STORAGE_NAMESPACE_ADDRESS_TO_FACET_MAP = "DiamondStorage.namespace.addressToFacetMap";

    /**
     * @dev Structure representing a Diamond facet, storing its function selectors.
     */
    struct DiamondFacet {
        bytes4[] functionSelectors;
    }
    
    /**
     * @dev Structure for an enumerable mapping from address to DiamondFacet.
     */
    struct AddressToFacetMap {
        EnumerableSet.AddressSet _keys;
        mapping(address => DiamondFacet) _values;
    }

    /**
     * @dev Retrieves the AddressToFacetMap storage by its name.
     * @param facetMapName The name of the facet map.
     * @return The storage reference to AddressToFacetMap.
     */
    function getAddressToFacetMap(string memory facetMapName) internal pure returns (AddressToFacetMap storage) {
        string memory mapSeed = _concat(DIAMOND_STORAGE_NAMESPACE_ADDRESS_TO_FACET_MAP, facetMapName);
        bytes32 slot = mapSeed.erc7201Slot();
        return _getAddressToFacetMap(slot);
    }

    /**
     * @dev Internal function to retrieve the AddressToFacetMap from a specific storage slot.
     * @param slot The storage slot.
     */
    function _getAddressToFacetMap(bytes32 slot) private pure returns (AddressToFacetMap storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Adds or updates a key-value pair in the map. O(1).
     * @param map The AddressToFacetMap storage.
     * @param key The address key.
     * @param value The DiamondFacet to associate with the key.
     * @return True if the key was added (i.e., not previously present).
     */
    function set(AddressToFacetMap storage map, address key, DiamondFacet memory value) internal returns (bool) {
        if (key == address(0)) {
            revert AddressKeyZero(key, value);
        }
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from the map. O(1).
     * @param map The AddressToFacetMap storage.
     * @param key The address key to remove.
     * @return True if the key was present and removed.
     */
    function remove(AddressToFacetMap storage map, address key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Checks if a key exists in the map. O(1).
     * @param map The AddressToFacetMap storage.
     * @param key The address key to check.
     * @return True if the key exists.
     */
    function contains(AddressToFacetMap storage map, address key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     * @param map The AddressToFacetMap storage.
     * @return The number of entries in the map.
     */
    function length(AddressToFacetMap storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Retrieves the key-value pair at a specific index. O(1).
     * @param map The AddressToFacetMap storage.
     * @param index The index of the key-value pair.
     * @return key The address key.
     * @return value The DiamondFacet associated with the key.
     */
    function at(AddressToFacetMap storage map, uint256 index) internal view returns (address key, DiamondFacet storage value) {
        address atKey = map._keys.at(index);
        return (atKey, map._values[atKey]);
    }

    /**
     * @dev Retrieves the value for a key, or initializes it if absent. O(1).
     * @param map The AddressToFacetMap storage.
     * @param key The address key.
     * @return The DiamondFacet storage reference.
     */
    function computeIfAbsent(AddressToFacetMap storage map, address key) internal returns (DiamondFacet storage) {
        if (contains(map, key)) {
            return map._values[key];
        } else {
            map._keys.add(key);
            return map._values[key];
        }
    }

    /**
     * @dev Retrieves the value for a key. Reverts if the key is not present. O(1).
     * @param map The AddressToFacetMap storage.
     * @param key The address key.
     * @return The DiamondFacet storage reference.
     */
    function get(AddressToFacetMap storage map, address key) internal view returns (DiamondFacet storage) {
        if (!contains(map, key)) {
            revert AddressToFacetMapNonexistentKey(key);
        }
        return map._values[key];
    }

    /**
     * @dev Returns all keys in the map.
     * @param map The AddressToFacetMap storage.
     * @return An array of addresses representing all keys.
     *
     * @notice This operation copies all storage keys to memory and may be expensive for large maps.
     */
    function keys(AddressToFacetMap storage map) internal view returns (address[] memory) {
        return map._keys.values();
    }
}
