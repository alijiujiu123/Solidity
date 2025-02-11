// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "contracts/proxy/EIP2535/DiamondUtils.sol";
import "contracts/proxy/EIP2535/IDiamondCut.sol";
import "contracts/proxy/EIP2535/IDiamondLoupe.sol";
import "contracts/proxy/EIP2535/DiamondStorage.sol";
import "contracts/proxy/EIP2535/CommonStorage.sol";

// Deployment Process:
// 1. Deploy DiamondCutFacet and DiamondLoupeFacet.
// 2. Deploy DiamondProxy: 
//    - Pass the DiamondCutFacet address to register the diamondCut function.
//    - Pass the DiamondLoupeFacet address to register the loupe functions.
// 3. Deploy business contracts and register their interfaces with the proxy.
contract DiamondProxy is CommonStorage {
    using DiamondUtils for *;
    using DiamondStorage for *;

    error FacetNotRegistered(address sender, bytes4 sig);

    event InitCalldataExecuted(address indexed diamondCutAddress, IDiamondCut.FacetCut[] _diamondCut, bool success, bytes resultData);

    constructor1(address diamondCutAddress, address diamondLoupeAddress) {
        // 1. Register the diamondCut function from DiamondCutFacet
        _registerDiamondCut(diamondCutAddress);
        // 2. Register the loupe functions from DiamondLoupeFacet
        _registerDiamondLoupe(diamondCutAddress, diamondLoupeAddress);
    }

    // Fallback function to delegate calls to registered facets
    fallback() external payable { 
        bytes4 sig = msg.sig;
        // Use low-level DiamondStorage to fetch facetAddress:
        // 1. Reduces extra call overhead.
        // 2. Ensures business contracts function even if DiamondLoupeFacet is incorrectly upgraded.
        address facetAddress = getSigFacetAddressMapping().get(sig);
        if (facetAddress == address(0)) {
            revert FacetNotRegistered(msg.sender, sig);
        }
        // Directly delegate the call to the facet
        facetAddress.delegate();
    }

    receive() external payable {}

    // Register the diamondCut function from DiamondCutFacet
    function _registerDiamondCut(address diamondCutAddress) private {
        // Prepare FacetCut structure
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = IDiamondCut.diamondCut.selector;

        IDiamondCut.FacetCut[] memory _diamondCut = new IDiamondCut.FacetCut[](1);
        _diamondCut[0] = IDiamond.FacetCut({
            facetAddress: diamondCutAddress,
            action: IDiamond.FacetCutAction.Add,  // 0 = Add
            functionSelectors: selectors
        });

        _registerFacet(diamondCutAddress, _diamondCut, address(0), bytes(""));
    }
    
    // Register the loupe functions from DiamondLoupeFacet
    function _registerDiamondLoupe(address diamondCutAddress, address diamondLoupeAddress) private {
        // Prepare FacetCut structure for loupe functions
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = IDiamondLoupe.facets.selector;
        selectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        selectors[2] = IDiamondLoupe.facetAddresses.selector;
        selectors[3] = IDiamondLoupe.facetAddress.selector;

        IDiamondCut.FacetCut[] memory _diamondCut = new IDiamondCut.FacetCut[](1);
        _diamondCut[0] = IDiamond.FacetCut({
            facetAddress: diamondLoupeAddress,
            action: IDiamond.FacetCutAction.Add,  // 0 = Add
            functionSelectors: selectors
        });

        _registerFacet(diamondCutAddress, _diamondCut, address(0), bytes(""));
    }

    // Register provided FacetCut structure with the diamondCut function
    function _registerFacet(address diamondCutAddress, IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) private {
        // ABI encode the parameters for the diamondCut call
        bytes memory encodedData = abi.encodeWithSelector(
            IDiamondCut.diamondCut.selector,  // Get the selector for diamondCut
            _diamondCut,
            _init,
            _calldata  // Optional calldata for initialization, can be empty
        );

        // Delegatecall to execute diamondCut on the provided facet
        (bool success, bytes memory resultData) = diamondCutAddress.delegatecall(encodedData);

        emit InitCalldataExecuted(diamondCutAddress, _diamondCut, success, resultData);
    }
}
