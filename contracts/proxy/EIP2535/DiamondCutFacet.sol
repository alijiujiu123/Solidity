// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "contracts/proxy/EIP2535/IDiamondCut.sol";
import "contracts/proxy/EIP2535/DiamondStorage.sol";
import "contracts/proxy/EIP2535/CommonStorage.sol";
import "contracts/proxy/EIP2535/ArrayUtils.sol";

/**
 * @title DiamondCutFacet
 * @dev Implements the DiamondCut functionality as per EIP-2535.
 * This contract allows adding, replacing, and removing function selectors associated with facets.
 * Future TODO: Implement role-based permission management at the facet or selector level.
 */
contract DiamondCutFacet is IDiamondCut, CommonStorage {
    using DiamondStorage for *;
    using ArrayUtils for *;

    // Custom errors for more descriptive revert messages
    error FacetCutArrayEmpty();
    error FacetAddressZero();
    error FacetCutActionIllegal();
    error FunctionSelectorsEmpty();
    error AddSelectorAlreadyExist(bytes4 selector, address newAddress, address oldAddress);
    error ReplaceSelectorNotExist(bytes4 selector, address newAddress);
    error SelectorIllegal(bytes4 selector);

    // Event emitted after executing _init calldata during diamondCut
    event InitCalldataExecute(address indexed _init, bytes _calldata, bool ok, bytes resultData);

    /**
     * @notice Add, replace, or remove functions from facets and optionally execute an initialization function.
     * @param _diamondCut Array of facet modifications (add, replace, remove).
     * @param _init Address of the contract or facet where _calldata will be executed.
     * @param _calldata Function call data to be executed on _init using delegatecall.
     */
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external {
        uint facetsCutLength = _diamondCut.length;
        
        // Check that the diamondCut array is not empty
        if (facetsCutLength == 0) {
            revert FacetCutArrayEmpty();
        }

        // Process each FacetCut action
        for (uint i = 0; i < facetsCutLength; i++) {
            FacetCut calldata currentFacetCut = _diamondCut[i];
            _checkFacetCut(currentFacetCut);

            // Execute the corresponding action
            if (currentFacetCut.action == FacetCutAction.Add) {
                _addFacetCut(currentFacetCut);
            } else if (currentFacetCut.action == FacetCutAction.Replace) {
                _replaceFacetCut(currentFacetCut);
            } else if (currentFacetCut.action == FacetCutAction.Remove) {
                _removeFacetCut(currentFacetCut);
            }
        }

        // Execute optional initialization via delegatecall
        _delegatecall(_init, _calldata);

        // Emit event after successful diamondCut
        emit DiamondCut(_diamondCut, _init, _calldata);
    }

    /**
     * @dev Validates the FacetCut data before applying changes.
     * Reverts if facet address is zero, action is invalid, or selectors are empty or zero.
     */
    function _checkFacetCut(FacetCut calldata _facetCut) private pure {
        if (_facetCut.facetAddress == address(0)) {
            revert FacetAddressZero();
        }
        if (!_isValidFacetCutAction(_facetCut.action)) {
            revert FacetCutActionIllegal();
        }
        if (_facetCut.functionSelectors.length == 0) {
            revert FunctionSelectorsEmpty();
        }

        // Ensure all selectors are valid (non-zero)
        for (uint i = 0; i < _facetCut.functionSelectors.length; i++) {
            if (_facetCut.functionSelectors[i] == bytes4(0)) {
                revert SelectorIllegal(_facetCut.functionSelectors[i]);
            }
        }
    }

    /**
     * @dev Checks if the provided FacetCutAction is valid.
     * @return true if the action is Add, Replace, or Remove.
     */
    function _isValidFacetCutAction(FacetCutAction action) private pure returns (bool) {
        return action <= FacetCutAction.Remove;
    }

    /**
     * @dev Adds new function selectors to a facet.
     * Reverts if any of the selectors already exist.
     */
    function _addFacetCut(FacetCut calldata _facetCut) private {
        bytes4[] calldata functionSelectors = _facetCut.functionSelectors;
        address currentFacetAddress = _facetCut.facetAddress;

        // Update selector-to-facet address mapping
        for (uint i = 0; i < functionSelectors.length; i++) {
            bytes4 selector = functionSelectors[i];
            address existingAddress = getSigFacetAddressMapping().get(selector);

            if (existingAddress != address(0)) {
                revert AddSelectorAlreadyExist(selector, currentFacetAddress, existingAddress);
            }

            getSigFacetAddressMapping().set(selector, currentFacetAddress);
        }

        // Update facet-to-selector mapping
        _processAddFacetMapping(functionSelectors, currentFacetAddress);
    }

    /**
     * @dev Adds selectors to the AddressToFacetMap.
     * Ensures no duplicate selectors exist for the same facet.
     */
    function _processAddFacetMapping(bytes4[] memory selectors, address facetAddress) private {
        DiamondStorage.AddressToFacetMap storage addressToFacetMap = getAddressToFacetMap();
        DiamondStorage.DiamondFacet storage facet = addressToFacetMap.computeIfAbsent(facetAddress);

        for (uint i = 0; i < selectors.length; i++) {
            if (!facet.functionSelectors.contains(selectors[i])) {
                facet.functionSelectors.push(selectors[i]);
            }
        }
    }

    /**
     * @dev Replaces existing function selectors with new facet addresses.
     * Reverts if a selector does not exist.
     */
    function _replaceFacetCut(FacetCut calldata _facetCut) private {
        bytes4[] calldata functionSelectors = _facetCut.functionSelectors;
        address newFacetAddress = _facetCut.facetAddress;

        for (uint i = 0; i < functionSelectors.length; i++) {
            bytes4 selector = functionSelectors[i];
            address oldFacetAddress = getSigFacetAddressMapping().get(selector);

            if (oldFacetAddress == address(0)) {
                revert ReplaceSelectorNotExist(selector, newFacetAddress);
            }

            getSigFacetAddressMapping().set(selector, newFacetAddress);
            _processReplaceFacetMapping(selector, oldFacetAddress, newFacetAddress);
        }
    }

    /**
     * @dev Handles updating the AddressToFacetMap when replacing a selector.
     */
    function _processReplaceFacetMapping(bytes4 selector, address oldFacetAddress, address newFacetAddress) private {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = selector;
        _processRemoveFacetMapping(selectors, oldFacetAddress);
        _processAddFacetMapping(selectors, newFacetAddress);
    }

    /**
     * @dev Removes function selectors from a facet.
     */
    function _removeFacetCut(FacetCut calldata _facetCut) private {
        bytes4[] calldata functionSelectors = _facetCut.functionSelectors;

        for (uint i = 0; i < functionSelectors.length; i++) {
            bytes4 selector = functionSelectors[i];
            address facetAddress = getSigFacetAddressMapping().get(selector);

            if (facetAddress != address(0)) {
                getSigFacetAddressMapping().remove(selector);
            }
        }

        _processRemoveFacetMapping(functionSelectors, _facetCut.facetAddress);
    }

    /**
     * @dev Removes selectors from AddressToFacetMap and deletes the facet if no selectors remain.
     */
    function _processRemoveFacetMapping(bytes4[] memory selectors, address facetAddress) private {
        DiamondStorage.AddressToFacetMap storage addressToFacetMap = getAddressToFacetMap();

        if (addressToFacetMap.contains(facetAddress)) {
            DiamondStorage.DiamondFacet storage facet = addressToFacetMap.get(facetAddress);
            facet.functionSelectors = facet.functionSelectors.removeElements(selectors);

            if (facet.functionSelectors.length == 0) {
                addressToFacetMap.remove(facetAddress);
            }
        }
    }

    /**
     * @dev Executes an initialization function using delegatecall after diamondCut.
     */
    function _delegatecall(address _init, bytes calldata _calldata) private {
        if (_init != address(0) && _calldata.length > 0) {
            (bool ok, bytes memory resultData) = _init.delegatecall(_calldata);
            emit InitCalldataExecute(_init, _calldata, ok, resultData);
        }
    }
}
