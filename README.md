# 🛠 Solidity Smart Contract Libraries

This repository contains a collection of versatile **Solidity contracts and libraries** designed to enhance smart contract development. The modules cover **data structures**, **proxy patterns**, **access control**, and **security utilities** like **reentrancy locks**.

---

## 📚 Contents

1. [Generalized Linked List Structure](#1-generalized-linked-list-structure)
2. [Self-Implemented Upgrade Proxy (ERC1967)](#2-self-implemented-upgrade-proxy-erc1967)
3. [Authorized Contract with Time Limit](#3-authorized-contract-with-time-limit)
4. [Reentrancy Lock Libraries](#4-reentrancy-lock-libraries)

---

## 1. 🗂 Generalized Linked List Structure

A flexible linked list implementation supporting various data types, optimized for performance and gas efficiency.

### 📄 **Code Location**  
`contracts/structs/LinkedList.sol`

### ✨ **Features**

- **Multi-Type Support**: Stores `bytes32`, `uint256`, and `address` types.
- **CRUD Operations**: Add, remove, retrieve, and update elements with ease.
- **Queue Implementation**: Supports efficient **LIFO** (Last In, First Out) and **FIFO** (First In, First Out) queues.
- **Gas Optimized**: All operations are constant time **O(1)**, including `{clear}` (excluding `{values}`).

---

## 2. 🔄 Self-Implemented Upgrade Proxy Contract (ERC1967)

A custom implementation of an **upgradeable proxy** contract following the **ERC1967** standard, ensuring safe upgrades and storage consistency.

### 📄 **Code Location**  
`contracts/proxy/ERC1967/TransparentUpgradeableProxy.sol`

### ✨ **Features**

- **Fallback Handling**: Automatically forwards calls to the logic contract.
- **Assembly-Based Fallback**: `_fallback` function handles returned data using low-level assembly for optimized performance.
- **Upgradeable Logic**: Supports contract upgrades with configurable admin management (`adminAddress`).
- **Memory Layout Consistency**: Maintains a consistent layout using custom storage slots, adhering to ERC1967 standards.
- **Initialization Logic**: Calls initialization routines during deployment or upgrades.

---

## 3. ⏳ Authorized Contract with Time Limit

A utility contract providing **access control** mechanisms with **time-limited permissions**.

### 📄 **Code Location**  
`contracts/utils/GrantPrivileges.sol`

### ✨ **Features**

- **Access Control**: Supports both **Admin** and **Owner** roles for secure management.
- **Time-Based Authorization**: Grants permissions for specific time durations, automatically revoking access afterward.
- **Upgradeable Admin Role**: Allows dynamic management of admin addresses for flexible control.

---

## 4. 🔒 Reentrancy Lock Libraries

Robust **reentrancy protection** for smart contracts with both **transient storage-based** and **standard storage-based** locks.

### 📄 **Code Locations**

- **Transient Storage-Based Locks (EIP-1153)**  
  Efficient, gas-optimized locks that automatically reset at the end of each transaction.
  - `contracts/utils/AbstractNonReentrantLockTransient.sol`
  - `contracts/utils/NonReentrantLockTransient.sol`

- **Standard Storage-Based Locks**  
  Traditional storage-based locks for chains without EIP-1153 support.
  - `contracts/utils/AbstractNonReentrantLock.sol`
  - `contracts/utils/NonReentrantLock.sol`

### ✨ **Features**

- **Default & Custom Locks**: Apply simple default locks or create fine-grained, customizable locks using unique seeds.
- **Gas Optimization**: Transient storage resets automatically at transaction end, reducing gas costs.
- **Reusable Modifiers**: Simplified reentrancy protection with `nonReentrantLock` and `nonReentrantcustomizeLock`.
- **EIP-1153 Support**: Fully compatible with chains supporting **EIP-1153**, with standard storage fallback.

---

## 🛠 Example Usage

### 🔄 Using Transient Storage Locks (EIP-1153)

```solidity
import "./AbstractNonReentrantLockTransient.sol";

contract MyContract is AbstractNonReentrantLockTransient {
    uint256 private _balance;

    // Default transient lock
    function deposit() external nonReentrantLock {
        _balance += 1;
    }

    // Custom transient lock with unique seed
    function withdraw() external nonReentrantcustomizeLock("withdraw.lock") {
        require(_balance > 0, "Insufficient balance");
        _balance -= 1;
    }
}
