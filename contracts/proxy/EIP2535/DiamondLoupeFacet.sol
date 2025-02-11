// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "contracts/proxy/EIP2535/IDiamondLoupe.sol";
import "contracts/proxy/EIP2535/DiamondStorage.sol";
import "contracts/proxy/EIP2535/CommonStorage.sol";

/**
 * @title DiamondLoupeFacet
 * @dev Implements the loupe functions as defined in EIP-2535.
 * These functions allow querying information about the facets and function selectors of a diamond.
 * This is particularly useful for user interfaces to visualize the structure of a diamond contract.
 */
contract DiamondLoupeFacet is IDiamondLoupe, CommonStorage {
    using DiamondStorage for *;

    /**
     * @notice Returns all facet addresses and their corresponding function selectors.
     * @return facets_ An array of Facet structs, each containing a facet address and its function selectors.
     */
    function facets() external view returns (Facet[] memory facets_) {
        DiamondStorage.AddressToFacetMap storage addressToFacetMap = getAddressToFacetMap();
        
        // Retrieve all facet addresses stored in the mapping
        address[] memory _facetAddresses = addressToFacetMap.keys();
        uint len = _facetAddresses.length;

        // If no facets exist, return an empty array
        if (len == 0) {
            return new Facet[](0);
        }

        facets_ = new Facet[](len);

        // Iterate through each facet address to populate the facets array
        for (uint i = 0; i < len; i++) {
            address currentAddress = _facetAddresses[i];
            
            // Ensure the facet exists in the mapping before accessing it
            if (addressToFacetMap.contains(currentAddress)) {
                DiamondStorage.DiamondFacet storage diamondFacet = addressToFacetMap.get(currentAddress);
                facets_[i].facetAddress = currentAddress;
                facets_[i].functionSelectors = diamondFacet.functionSelectors;
            }
        }
    }

    /**
     * @notice Returns all function selectors supported by a specific facet.
     * @param _facet The address of the facet.
     * @return facetFunctionSelectors_ An array of function selectors associated with the facet.
     */
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_) {
        DiamondStorage.AddressToFacetMap storage addressToFacetMap = getAddressToFacetMap();
        
        // If the facet exists, return its function selectors
        if (addressToFacetMap.contains(_facet)) {
            DiamondStorage.DiamondFacet storage diamondFacet = addressToFacetMap.get(_facet);
            facetFunctionSelectors_ = diamondFacet.functionSelectors;
        }
    }

    /**
     * @notice Returns all facet addresses used by the diamond.
     * @return facetAddresses_ An array of addresses representing all facets in the diamond.
     */
    function facetAddresses() external view returns (address[] memory facetAddresses_) {
        DiamondStorage.AddressToFacetMap storage addressToFacetMap = getAddressToFacetMap();
        
        // Retrieve all facet addresses from the mapping
        facetAddresses_ = addressToFacetMap.keys();
    }

    /**
     * @notice Returns the facet address that supports the given function selector.
     * @dev If no facet is found for the selector, returns address(0).
     * @param _functionSelector The function selector to query.
     * @return facetAddress_ The address of the facet that supports the given selector.
     */
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_) {
        return getSigFacetAddressMapping().get(_functionSelector);
    }
}
