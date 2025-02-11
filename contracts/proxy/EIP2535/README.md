# EIP-2535 Diamond Standard Implementation

This repository provides a custom implementation of the [EIP-2535 Diamond Standard](https://eips.ethereum.org/EIPS/eip-2535). The Diamond Standard enables flexible and modular smart contract development through the use of facets, allowing dynamic addition, replacement, and removal of functions.

---

## Table of Contents

- [Overview](#overview)
- [Deployment Process](#deployment-process)
- [Contracts Description](#contracts-description)
  - [DiamondCutFacet](#diamondcutfacet)
  - [DiamondLoupeFacet](#diamondloupefacet)
  - [DiamondProxy](#diamondproxy)
  - [CommonStorage & DiamondStorage](#commonstorage--diamondstorage)
    - [DiamondStorage Overview](#diamondstorage-overview)
    - [Key Features of DiamondStorage](#key-features-of-diamondstorage)
    - [DiamondStorage Structures](#diamondstorage-structures)

---

## Overview

The Diamond Standard allows for:
- Adding, replacing, and removing functions dynamically.
- Efficient storage management and modular upgrades.
- Improved contract management via facets.

This implementation includes core contracts for managing the diamond lifecycle, querying facets, and handling storage.

---

## Deployment Process

1. **Deploy `DiamondCutFacet` and `DiamondLoupeFacet`**  
   These are the core facets for managing and querying diamond functionalities.
   
2. **Deploy `DiamondProxy`**  
   Initialize with the addresses of the `DiamondCutFacet` and `DiamondLoupeFacet`. This sets up the proxy to route function calls to the appropriate facets.
   
3. **Deploy and Register Business Logic Facets**  
   Deploy custom facets containing business logic and register them with the diamond using the `diamondCut` function.

---

## Contracts Description

### DiamondCutFacet

Handles the addition, replacement, and removal of function selectors.

**Key Functions:**
- `diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata)`  
  Executes the diamond cut, modifying facets and optionally running initialization logic.

**Error Handling:**
- `FacetCutArrayEmpty()`: Reverts if no facet modifications are provided.
- `FacetAddressZero()`: Reverts if a zero address is passed for a facet.
- `AddSelectorAlreadyExist()`: Reverts if trying to add a function selector that already exists.
- `ReplaceSelectorNotExist()`: Reverts if attempting to replace a function that doesn’t exist.

---

### DiamondLoupeFacet

Provides functions to inspect the diamond structure, essential for UI interactions and contract management.

**Key Functions:**
- `facets()`: Returns all facets and their selectors.
- `facetFunctionSelectors(address _facet)`: Returns selectors for a specific facet.
- `facetAddresses()`: Lists all facet addresses.
- `facetAddress(bytes4 _functionSelector)`: Returns the facet address supporting a selector.

---

### DiamondProxy

Acts as the main contract that delegates calls to appropriate facets.

**Key Functions:**
- `fallback()` and `receive()`: Routes function calls to the correct facet or reverts if the function is unregistered.
- `_registDiamondCut(address diamondCutAddress)`: Registers the `diamondCut` function.
- `_registDiamondLoupe(address diamondCutAddress, address diamondLoupeAddress)`: Registers the loupe functions for querying facets.

**Error Handling:**
- `FacetNotRegist(address sender, bytes4 sig)`: Thrown when a function is called that isn't registered.

---

### CommonStorage & DiamondStorage

These contracts manage shared storage for the diamond and its facets, ensuring data integrity and efficient lookups.

---

#### DiamondStorage Overview

`DiamondStorage` is a utility library that underpins the dynamic behavior of EIP-2535 diamonds by managing mappings between function selectors and facet addresses. It also tracks facets and their functions, ensuring efficient and organized storage operations.

This library is designed for:
- **Efficient function selector management**: Mapping `bytes4` function selectors to their corresponding facet addresses.
- **Facet organization and tracking**: Maintaining an enumerable mapping of facets and their function selectors.

---

#### Key Features of DiamondStorage

- **Namespaced Storage**: Ensures modularity and prevents storage collisions by using unique namespaces.
- **Slot Derivation Utilities**: Leverages `SlotDerivation` and `StorageSlot` for precise and predictable storage management.
- **Enumerable Facet Management**: Tracks facets and their function selectors using efficient data structures.
- **Error Handling**: Provides custom, gas-efficient error messages for common issues like zero-address entries or missing facets.
- **Extensibility**: Easily extendable to support custom facet management logic.

---

#### DiamondStorage Structures

The library offers two main storage structures:

1. **Bytes4 to Address Mapping**

   Maps function selectors (`bytes4`) to facet addresses, enabling quick lookup of which facet implements a specific function.

   **Namespace**: `"DiamondStorage.namespace.bytes4ToAddressMap"`

   **Core Functions**:
   - `getBytes4ToAddressMap(string memory mapName)`: Retrieves the storage slot for a selector-to-address mapping.
   - `get(Bytes4ToAddressMap _map, bytes4 key)`: Returns the facet address for a given function selector.
   - `set(Bytes4ToAddressMap _map, bytes4 key, address _value)`: Maps a function selector to a facet address.
   - `remove(Bytes4ToAddressMap _map, bytes4 key)`: Removes a selector-to-address mapping.

2. **Address to DiamondFacet Mapping**

   Maintains a mapping from facet addresses to their corresponding function selectors. This structure supports enumeration, allowing for introspection of facets.

   **Namespace**: `"DiamondStorage.namespace.addressToFacetMap"`

   **Structures**:

   <details>
   <summary>Click to expand NonReentrantLock example</summary>
     
   ```solidity
   struct DiamondFacet {
       bytes4[] functionSelectors;
   }

   struct AddressToFacetMap {
       EnumerableSet.AddressSet _keys;
       mapping(address => DiamondFacet) _values;
   }
   ```
   </details>
