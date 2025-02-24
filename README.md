# 🛠 Solidity Smart Contract Libraries

This repository contains a collection of versatile **Solidity contracts and libraries** designed to enhance smart contract development. The modules cover **data structures**, **proxy patterns**, **access control**, and **security utilities** like **reentrancy locks**.

---

## 📚 Contents

### 🏗 Data Structures
1. [Generalized Linked List Structure](#1-generalized-linked-list-structure)
2. [BitMaps & MultiBitsMaps](#2-bitmaps--multibitsmaps)

### 🔄 Proxy Implementations
3. [Self-Implemented Upgrade Proxy (ERC1967)](#3-self-implemented-upgrade-proxy-erc1967)
4. [EIP-2535 Diamond Standard Implementation](#4-eip-2535-diamond-standard-implementation)

### 🔒 Security & Utility Tools
5. [Grant Privileges Smart Contract](#5-grant-privileges-smart-contract)
6. [Reentrancy Lock Libraries](#6-reentrancy-lock-libraries)

---

## 🏗 1. Generalized Linked List Structure

A flexible linked list implementation supporting various data types, optimized for performance and gas efficiency.

### 📄 **Code Location**  
`contracts/structs/LinkedList.sol`

### ✨ **Features**

- **Multi-Type Support**: Stores `bytes32`, `uint256`, and `address` types.
- **CRUD Operations**: Add, remove, retrieve, and update elements with ease.
- **Queue Implementation**: Supports efficient **LIFO** (Last In, First Out) and **FIFO** (First In, First Out) queues.
- **Gas Optimized**: All operations are constant time **O(1)**, including `{clear}` (excluding `{values}`).

---

## 🏗 2. BitMaps & MultiBitsMaps

Efficient bitmap implementations to optimize storage and gas costs.

### 📄 **Code Location**
- `contracts/utils/BitMaps.sol`
- `contracts/utils/MultiBitsMaps.sol`

### ✨ **Features**

#### **BitMaps**
- **Boolean value storage**: Each bit represents `true` or `false`.
- **Compact representation**: Uses `uint256` mapping for gas efficiency.
- **Bitwise operations**: Supports setting, clearing, and checking bits.

#### **MultiBitsMaps**
- **Compact integer storage**: Packs small values into a single `uint256`.
- **Supported structures**:
  - `FourBitsMap`: Stores values from `{0, ..., 15}` (4-bit values).
  - `ByteMap`: Stores values from `{0, ..., 255}` (8-bit values).
- **Optimized storage**: Reduces `SSTORE` operations for lower gas costs.

---

## 🔄 3. Self-Implemented Transparent Upgradeable Proxy

A **Transparent Upgradeable Proxy** based on **EIP-1967**, ensuring smooth logic upgrades.

### 📄 **Code Location**
- `contracts/proxy/ERC1967/ERC1967Utils.sol`
- `contracts/proxy/ERC1967/ProxyAdmin.sol`
- `contracts/proxy/ERC1967/TransparentUpgradeableProxy.sol`

### ✨ **Features**

- **EIP-1967 Compliant**: Uses standard storage slots for proxy management.
- **Admin-Controlled Upgrades**: Allows only authorized addresses to upgrade the contract.
- **Transparent Proxy Pattern**: Prevents accidental admin calls by users.
- **Fallback and Receive Functions**: Supports forwarding of calls and Ether handling.

---

## 🔄 4. EIP-2535 Diamond Standard Implementation

A **modular and scalable smart contract system** that enables **dynamic function management**.

### 📄 **Code Location**
- `contracts/proxy/EIP2535/*.sol`

### ✨ **Features**

- **Modular Upgradability**: Functions can be added, replaced, or removed.
- **Storage Efficiency**: Uses structured storage for managing multiple facets.
- **Optimized Gas Usage**: Calls only relevant functions, reducing execution costs.

---

## 🔒 5. Grant Privileges Smart Contract

Implements **time-based access control**, allowing admins to grant temporary permissions.

### 📄 **Code Location**
- `contracts/utils/GrantPrivileges.sol`

### ✨ **Features**

- **Admin-Controlled Access**: Only the admin can manage privileged users.
- **Time-Limited Roles**: Users receive temporary access based on an expiration timestamp.
- **Dynamic Management**:
  - `addOwner(address, uint)`: Grants access to a user for a limited time.
  - `getRemainingTime()`: Checks remaining access time.
  - `changeAdmin(address)`: Transfers admin rights.

---

## 🔒 6. Reentrancy Lock Libraries

Provides **robust protection** against reentrancy attacks using **storage-based** and **transient storage-based locks (EIP-1153)**.

### 📄 **Code Locations**

- **Transient Storage-Based Locks (EIP-1153)**  
  - `contracts/utils/AbstractNonReentrantLockTransient.sol`
  - `contracts/utils/NonReentrantLockTransient.sol`

- **Standard Storage-Based Locks**  
  - `contracts/utils/AbstractNonReentrantLock.sol`
  - `contracts/utils/NonReentrantLock.sol`

### ✨ **Features**

- **Default & Custom Locks**: Supports simple and fine-grained locks.
- **Gas Optimization**: Transient storage locks reset automatically, reducing gas costs.
- **EIP-1153 Compatibility**: Uses transient storage if available, otherwise falls back to storage-based locks.

---

## 🚀 Contributing

We welcome contributions! Feel free to submit pull requests or open issues for improvements and bug fixes.

---

## 📜 License

This project is licensed under the **MIT License**.

