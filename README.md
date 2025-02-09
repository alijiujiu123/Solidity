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

## 2. 🔄 Self-Implemented Transparent Upgradeable Proxy

This project implements an **EIP-1967 compliant Transparent Upgradeable Proxy** pattern using Solidity. The proxy contract allows for seamless upgrades of logic contracts while maintaining storage consistency and access control via admin roles.

### Overview

- **`contracts/proxy/ERC1967/ERC1967Utils.sol`**: Utility library for managing storage slots and low-level delegate calls.
- **`contracts/proxy/ERC1967/ProxyAdmin.sol`**: Handles admin permissions, restricting upgrade and management functions to authorized addresses.
- **`contracts/proxy/ERC1967/TransparentUpgradeableProxy.sol`**: The main proxy contract that forwards calls to logic contracts, with built-in upgradeability and admin control.

### Features

- **EIP-1967 Storage Compliance**: Ensures consistent memory layout using predefined storage slots for implementation and admin addresses.
- **Transparent Proxy Pattern**: Separates admin functions from user interactions, preventing accidental administrative calls by regular users.
- **Upgradeable Logic Contracts**: Allows the admin to upgrade the logic contract and optionally initialize the new implementation.
- **Admin Control**: Secure admin role management with the ability to transfer permissions.
- **Fallback and Receive Functions**: Supports forwarding of calls and Ether handling through `fallback()` and `receive()` functions.

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

### 🔄 Standard Storage-Based Locks

<details>
  <summary>Click to expand AbstractNonReentrantLock example</summary>

```solidity
import "contracts/utils/AbstractNonReentrantLock.sol";

contract MyContract is AbstractNonReentrantLock {
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
```
</details>

<details>
  <summary>Click to expand NonReentrantLock example</summary>

```solidity
import "contracts/utils/NonReentrantLock.sol";

contract MyContract {
    using NonReentrantLock for *;
    uint256 private _balance;

    // Default transient lock
    function deposit() external {
        NonReentrantLock.NonReentrantLock memory lock = NonReentrantLock.getLock();
        lock.lock();
        _balance += 1;
        lock.unlock();
        // do some thing else
    }

    // Custom transient lock with unique seed
    function withdraw() external nonReentrantcustomizeLock("withdraw.lock") {
        require(_balance > 0, "Insufficient balance");
        NonReentrantLock.NonReentrantLock memory lock = NonReentrantLock.getLock("withdraw.lock");
        lock.lock();
        _balance -= 1;
        lock.unlock();
        // do some thing else
    }
}
```
</details>

### 🔄 Using Transient Storage Locks (EIP-1153)

<details>
  <summary>Click to expand AbstractNonReentrantLockTransient example</summary>

```solidity
import "contracts/utils/AbstractNonReentrantLockTransient.sol";

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
```
</details>

<details>
  <summary>Click to expand NonReentrantLockTransient example</summary>

```solidity
import "contracts/utils/NonReentrantLockTransient.sol";

contract MyContract {
    using NonReentrantLockTransient for *;
    uint256 private _balance;

    // Default transient lock
    function deposit() external {
        NonReentrantLockTransient.NonReentrantLock memory lock = NonReentrantLockTransient.getLock();
        lock.lock();
        _balance += 1;
        lock.unlock();
    }

    // Custom transient lock with unique seed
    function withdraw() external nonReentrantcustomizeLock("withdraw.lock") {
        require(_balance > 0, "Insufficient balance");
        NonReentrantLockTransient.NonReentrantLock memory lock = NonReentrantLockTransient.getLock("withdraw.lock");
        lock.lock();
        _balance -= 1;
        lock.unlock();
    }
}
```
</details>
