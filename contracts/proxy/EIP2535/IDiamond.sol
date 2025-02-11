// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
// A DiamondCut event must be emitted any time external functions are added, replaced, or removed.
// This applies to all upgrades, all functions changes, at any time, whether through diamondCut or not.
interface IDiamond {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}
