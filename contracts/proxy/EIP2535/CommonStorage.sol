// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "contracts/proxy/EIP2535/DiamondStorage.sol";

/**
 * @title CommonStorage
 * @dev Provides shared storage access for DiamondCut and DiamondLoupe as per EIP-2535 (Diamond Standard).
 * This contract defines common mappings and utility functions to manage facets and their function selectors.
 */
abstract contract CommonStorage {
    using DiamondStorage for *;

    // ***************************** Part One: bytes4(msg.sig) -> facetAddress mapping *****************************

    // Constant key for mapping function selectors (bytes4) to facet addresses.
    string internal constant SIG_FACET_ADDRESS_MAPPING_NAME = "eip2535.sigFacetAddressMapping";

    // ***************************** Part Two: address -> IDiamondLoupe.Facet *****************************

    // Constant key for mapping facet addresses to their respective facet data (function selectors).
    string internal constant ADDRESS_FACET_MAPPING_NAME = "eip2535.addressToFacetMap";

    /**
     * @dev Retrieves the mapping from function selectors (bytes4) to facet addresses.
     * @return The Bytes4ToAddressMap for selector-to-address mapping.
     */
    function getSigFacetAddressMapping() internal pure returns (DiamondStorage.Bytes4ToAddressMap) {
        return SIG_FACET_ADDRESS_MAPPING_NAME.getBytes4ToAddressMap();
    }

    /**
     * @dev Retrieves the mapping from facet addresses to their corresponding facet data.
     * @return The AddressToFacetMap storage for address-to-facet mapping.
     */
    function getAddressToFacetMap() internal pure returns (DiamondStorage.AddressToFacetMap storage) {
        return ADDRESS_FACET_MAPPING_NAME.getAddressToFacetMap();
    }

    /**
     * @dev Computes the function selector from a given function signature string.
     * Example: "transfer(address,uint256)" returns the selector for the transfer function.
     * @param funcSign The function signature as a string.
     * @return The bytes4 function selector.
     */
    function getSelector(string memory funcSign) external pure returns (bytes4) {
        return bytes4(keccak256(abi.encodePacked(funcSign)));
    }
}
